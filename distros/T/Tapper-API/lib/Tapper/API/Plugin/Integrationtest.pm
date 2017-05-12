package Tapper::API::Plugin::Integrationtest;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: API functions for integration tests
$Tapper::API::Plugin::Integrationtest::VERSION = '5.0.1';
use warnings;
use strict;
use 5.010;

use Mojolicious::Lite;
use JSON::XS;
use Tapper::Cmd::Testplan;
use Tapper::Cmd::Host;
use Tapper::Cmd::Testrun;
use Tapper::Model 'model';
use File::ShareDir;
use File::Spec;
use Storable;

my $cfg      = Tapper::Config->subconfig;
my %tests = (
             "example1" => {groups => ["ALL"], timeout => 8000},
             "example2" => {groups => ["ALL"], timeout => 3600*24*2},
            );


sub get_groups
{
        my %groups;
        foreach my $test (keys %tests) {
                foreach my $group (@{$tests{$test}->{groups} || []}) {
                        $groups{$group} //= [];
                        push @{$groups{$group}}, {name => $test, %{$tests{$test}}};
                }
        }
        return \%groups;
}


put 'host-new/room/:room/ip/:ip' => sub {
        my $self = shift;
        my $room = $self->param('room');
        my $ip = $self->param('ip');
        $self->render(json => {id => 12}, status => 201);
};

put 'host-new/name/:name' => sub {
        my $self = shift;
        my $name = $self->param('name');
        my ($room, $ip) = split('-', $name, 2);  # if multiple dashes are in $name, they end up in $ip
        $self->render(json => {id => 12}, status => 201);
};

put 'testrun-start/:testrun' => sub {
        my $self = shift;
        $self->app->renderer->default_format('json');


        my $data;
        if ($self->tx->req->body) {
                $data = eval{JSON::XS::decode_json($self->tx->req->body)};
                if ($@) {
                        $self->render(json => {
                                               error => $@
                                              },
                                      status => 409,
                                     );
                        return;
                }
        }

        if ($data->{group}) {
                my $tests = get_groups()->{$data->{group}};
                push @{$data->{tests}}, @$tests;
        }

        my $test = $self->param('testrun');
        my $test_filename = File::Spec->catfile($cfg->{paths}->{use_case_path},"$test.sc");
        if (not -r $test_filename) {
                $test_filename = File::Spec->catfile($cfg->{paths}->{use_case_path},"$test.mpc");
                if (not -r $test_filename) {
                        my $error = "Tried to find testrun description in ";
                          $error .= File::Spec->catfile($cfg->{paths}->{use_case_path},"$test.sc");
                          $error .= " and $test_filename. Neither was readable.";
                        $self->respond_to(json => {json => {error => $error}, status => 409,},
                                          any  => {text => "Error - $error", status => 409,},
                                 );
                return;

                }
        }
        my $cmd = Tapper::Cmd::Testrun->new();

        my $test_string = eval{$cmd->apply_macro($test_filename, $data)};
        if ($@) {
                $self->respond_to(json => {json => {error => "$@"}, status => 409,},
                                  any  => {text => "Error - $@", status => 409,},
                                 );
                return;
        }
        if ($data->{dryrun}) {
                $self->render(text => $test_string,
                              status => 202,
                             );
                return;
        }

        my @ids = eval {
                        require YAML::Syck;
                        my @plan = YAML::Syck::Load($test_string);
                        if ($plan[0]->{scenario_type}) {
                                require Tapper::Cmd::Scenario;
                                return Tapper::Cmd::Scenario->new()->add(\@plan); # returns from eval block
                        }
                        # we have a plain precondition description without additional testrun description
                        # need to add options that $cmd->create needs
                        elsif (not $plan[0]->{preconditions}) {
                                # don't use \@plan, since we overwrite it in the next step
                                my $tmp_plan = { preconditions => [ @plan ], topic => uc($test) };
                                @plan = ($tmp_plan);
                        }
                        $cmd->create($plan[0]);
        };
        if ($@) {
                $self->respond_to(json => {json => {error => "$@"}, status => 409,},
                                  any  => {text => "Error - $@", status => 409,},
                                 );
                return;
        }
        my $text_return;
        foreach my $id (@ids) {
                $text_return .= "url: $cfg->{base_url}/testrun/id/$id\n";
        }
        $self->respond_to(json => {json => {testrun => {
                                                         ids => [ @ids ],
                                                         links => [ map {"$cfg->{base_url}/testruns/id/$_"} @ids ],
                                                        },
                                           }, status => 202,
                                  },
                          any  => {text => $text_return, status => 202,},
                         );

};


put 'testplan-start/:testplan' => sub {
        my $self = shift;
        $self->app->renderer->default_format('json');


        my $data;
        if ($self->tx->req->body) {
                $data = eval{JSON::XS::decode_json($self->tx->req->body)};
                if ($@) {
                        $self->render(json => {
                                               error => $@
                                              },
                                      status => 409,
                                     );
                        return;
                }
        }

        # if host does not yet exist, create it and bind it to integrationtest queue
        if ($data->{hosts} and $data->{room}) {
        HOST:
                foreach my $host (@{$data->{hosts}}) {
                        my $room = $data->{room};
                        if (not $host =~ /$room-/i) {
                                $host = join("-",lc($room),$host);
                        }

                        my $host_r = Tapper::Model::model()->resultset('Host')->search({name => $host}, {rows => 1})->first;
                        if ($host_r) {
                                # hosts already in DB, activate it if needed
                                if (not $host_r->active) {
                                        $host_r->active(1);
                                        $host_r->update;
                                }
                                next HOST;
                        }
                        # host not in DB, create it
                        my $cmd = Tapper::Cmd::Host->new();
                        $cmd->add({name => $host,
                                   active => 1,
                                   free => 1,
                                   comment => '(autoadded by Tapper::API)'});

                        $host_r = Tapper::Model::model()->resultset('Host')->search({name => $host}, {rows => 1})->first;
                        my $queue_r = Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => 'integration'}, {rows => 1})->first;

                        # don't bind twice
                        next HOST if $host_r->queuehosts->search({queue_id => $queue_r->id}, {rows => 1})->first;
                        Tapper::Model::model('TestrunDB')->resultset('QueueHost')->new({queue_id => $queue_r->id,
                                                                                        host_id  => $host_r->id,
                                                                                       })->insert;

                }
        }

        my $cmd = Tapper::Cmd::Testplan->new();
        $data->{tests} //= [];

        if ($data->{group}) {
                my $tests = get_groups()->{$data->{group}};
                push @{$data->{tests}}, @$tests;
        }

        my $testplan = $self->param('testplan');
        my $plan_filename = File::Spec->catfile($cfg->{paths}->{testplan_path},
                                                lc((split(/::/,__PACKAGE__))[-1]), # last part of package name
                                                "$testplan.tp");

        my $safe_data=Storable::dclone($data); # make deep copy of substitute because TT changes them
        my $plan_evaluated = eval {$cmd->apply_macro($plan_filename, $data)};

        $data->{title} ||= $cmd->get_shortname($plan_evaluated);
        $data->{title} ||= $testplan;
        $data = $safe_data;

        if ($data->{dryrun}) {
                if ($@) {
                        $self->respond_to(json => {json => {error => "$@"}, status => 409,},
                                          any  => {text => "Error - $@", status => 409,},
                                         );
                } else {
                        $self->render(text => $plan_evaluated,
                                      status => 202,
                                     );
                }
                return;
        }

        my $id = eval {
                $cmd->testplannew(
                                  {
                                   file => $plan_filename,
                                   substitutes => $data,
                                   name => $data->{title},
                                  });
        };
        if ($@) {
                $self->respond_to(json => {json => {error => "$@"}, status => 409,},
                                  any  => {text => "Error - $@", status => 409,},
                                 );
                return;
        }
        my $tp = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        my @testplans = map { {id => $_->id, link => "$cfg->{base_url}/testruns/id/".$_->id }} $tp->testruns->all;
        $self->respond_to(json => {json => {testplan => {
                                                         id => $id,
                                                         link => "$cfg->{base_url}/testplan/id/$id",
                                                        },
                                            testrun  => \@testplans,
                                           }, status => 202,
                                  },
                          any  => {text => "Text - url: $cfg->{base_url}/testplan/id/$id\n", status => 202,},
                         );

};


get 'query/testplan-status/id/:testplan' => sub {
        my $self = shift;
        my $testplan = $self->param('testplan');
        my $cmd = Tapper::Cmd::Testplan->new();
        my $result = $cmd->status($testplan);
        $result->{link} = "$cfg->{base_url}/testplan/id/$testplan",
        $self->render(json => $result,
                      status => 202,
                     );
};

get 'query/testrun-status/id/:testrun' => sub {
        my $self = shift;
        my $testrun = $self->param('testrun');
        my $cmd = Tapper::Cmd::Testrun->new();
        my $result = $cmd->status($testrun);
        $result->{link} = "$cfg->{base_url}/testrun/id/$testrun",
        $self->render(json => $result,
                      status => 202,
                     );
};


put 'testrun-cancel/id/:testrun' => sub {
        my $self = shift;
        my $testrun = $self->param('testrun');
        $self->render(json => {
                               $testrun => {
                                            success => 'error',
                                            'error-msg' => 'You are not allowed to cancel this testrun'
                                           },
                              },
                      status => 202,
                     );
};

put 'testplan-cancel/id/:testplan' => sub {
        my $self = shift;
        my $testplan = $self->param('testplan');
        $self->render(json => {
                               success => 'canceled',
                               'error-msg' => undef,
                              },
                      status => 202,
                     );
};


get 'query/testplan-list/' => sub {
        my $self = shift;
        $self->render(json => {
                               collection => {
                                              options => ['room', 'group', 'tests', 'hosts']
                                             }
                              },
                      status => 202,
                     );
};


get 'query/test-list/' => sub {
        my $self = shift;
        $self->render(json => \%tests,
                      status => 202,
                     );
};

any 'query/report-filelist/id/:report_id' => sub {
        my $self = shift;
        $self->app->renderer->default_format('html');

        my $report_id = $self->param('report_id');
        my $filter_filename = $self->param('filter_filename');
        my $file_result;
        if ($filter_filename) {
                $file_result = model->resultset('ReportFile')->search({report_id => $report_id, filename => {'like' => $filter_filename}});
        } else {
                $file_result = model->resultset('ReportFile')->search({report_id => $report_id});
        }

        $self->respond_to(
                          json => sub { $self->render(json =>  {map {$_->id => $_->filename} $file_result->all} )},
                          html => sub {
                                  my $file_ids = [map {$_->id} $file_result->all];
                                  $self->stash(file_ids => $file_ids);
                                  $self->render(template => 'queryreportfilelistidreport_id')
                          }
                         );
};

any 'query/testrun-filelist/id/:testrun_id' => sub {
        my $self = shift;
        $self->app->renderer->default_format('html');

        my $cmd_testrun = Tapper::Cmd::Testrun->new();
        my $testrun_id = $self->param('testrun_id');
        my $reports_rs = model->resultset('ReportgroupTestrun')->search({testrun_id => $testrun_id, primaryreport => 1});
        my @report_ids = map {$_->report_id} $reports_rs->all;
        $self->stash(report_ids => \@report_ids);
};

any 'query/testplan-filelist/id/:testplan_id' => sub {
        my $self = shift;
        $self->app->renderer->default_format('html');

        my $testplan_id = $self->param('testplan_id');
        my $filter = $self->param('filter_filename');
        $filter ||= '%';

        my $cmd = Tapper::Cmd::Testplan->new();
        my $file_ids = $cmd->testplan_files($testplan_id, $filter);
        $self->stash(file_ids => $file_ids);
};

any 'query/reportfile/*filepath' => sub {
        my $self = shift;
        $self->app->renderer->default_format('html');

        my $filepath = $self->param('filepath');
        my $file_id = (split '/',$filepath)[-1];
        my $reportfile_result = model->resultset('ReportFile')->find($file_id);
        if (not $reportfile_result) {
                $self->render(text => "No file with '$filepath'",
                              status => 404,
                             );
                return;
        }

        my $filename = $reportfile_result->filename;
        my $contenttype = $reportfile_result->contenttype eq 'plain' ? 'text/plain' : $reportfile_result->contenttype;
        my $disposition = $contenttype =~ /plain/ ? 'inline' : 'attachment';
        $self->res->headers->content_type ($contenttype || 'application/octet-stream');
        $self->res->headers->content_disposition("$disposition; filename=$filename;");
        $self->render(text => $reportfile_result->filecontent, status => 202);
};


put 'host-delete/id/:host' => sub {
        my $self = shift;
        my $host = $self->param('host');
        $self->render(json => {$host => {success => 'deleted'}}, status => 202,);
};

1;

=pod

=encoding UTF-8

=head1 NAME

Tapper::API::Plugin::Integrationtest - API functions for integration tests

=head1 AUTHOR

Tapper Team <tapper-ops@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

__DATA__
@@querytestplanfilelistidtestplan_id.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>testplan file list</title>
 </head>
 <body>
<table>
% foreach my $file_id (@$file_ids){
    <tr><td valign="top"><a href="/api/integrationtestv1/query/reportfile/id/<%= $file_id %>"></a></td>
% }
</table>
</body></html>

@@querytestrunfilelistidtestrun_id.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>testrun file list</title>
 </head>
 <body>
<table>
% foreach my $report_id (@$report_ids){
    <tr><td valign="top"><a href="/api/integrationtestv1/query/report-filelist/id/<%= $report_id %>"></a></td>
% }
</table>
</body></html>

@@queryreportfilelistidreport_id.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>report file list</title>
 </head>
 <body>
<table>
% foreach my $file_id (@$file_ids){
    <tr><td valign="top"><a href="/api/integrationtestv1/query/reportfile/id/<%= $file_id %>"></a></td>
% }
</table>
</body></html>

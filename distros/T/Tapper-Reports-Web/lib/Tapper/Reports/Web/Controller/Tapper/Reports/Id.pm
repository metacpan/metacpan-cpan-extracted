package Tapper::Reports::Web::Controller::Tapper::Reports::Id;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Reports::Id::VERSION = '5.0.13';
use 5.010;
use strict;
use warnings;

use Tapper::Reports::Web::Util::Report;
use File::Basename;
use File::stat;
use parent 'Tapper::Reports::Web::Controller::Base';
use YAML;

use Data::Dumper;
use Data::DPath 'dpath';

sub younger
{
        my $astat = stat($a);
        my $bstat = stat($b);
        return $bstat->mtime() <=> $astat->mtime();
}



sub generate_metareport_link
{
        my ( $self, $report ) = @_;
        my %metareport;
        my $path = Tapper::Config->subconfig->{paths}{config_path};
        $path .= "/web/metareport_associate.yml";

        return if not -e $path;

        my $config;
        eval {
                $config = YAML::LoadFile($path);
        };
        if ($@) {
                # TODO: Enable Log4perl
                # $self->log->error("Can not open association config for metareports: $@");
                say STDERR "Can not open association config for metareports: $@";
                return ();
        }
        use Data::Dumper;
        my $suite;
        { no warnings 'uninitialized'; $suite = $config->{suite}->{$report->{suite}} || $config->{suite}->{$report->{group_suite}};}
        if ($suite) {
                my $category    = $suite->{category};
                my $subcategory = $suite->{subcategory};
                my $time_frame  = $suite->{time_frame};

                $path  = Tapper::Config->subconfig->{paths}{metareport_path};
                my ($filename) = sort younger <$path/$category/$subcategory/teaser/*.png>;
                if (not $filename) {
                        ($filename) = sort younger <$path/$category/$subcategory/$time_frame/*.png>;
                        $filename = "/tapper/static/metareports/$category/$subcategory/$time_frame/".basename($filename);
                } else {
                        $filename = "/tapper/static/metareports/$category/$subcategory/teaser/".basename($filename);
                }
                return () if not $filename;

                %metareport = (url => "/tapper/metareports/$category/$subcategory/$time_frame/",
                               img => $filename,
                               alt => $suite->{alt},
                               headline => $suite->{headline},
                              );
        }
        return %metareport;
}

# get array of not_ok sub tests

sub get_report_failures
{
        my ($self, $report) = @_;

        return [ dpath('//tap//lines//is_ok[value eq 0]/..')->match($report->get_cached_tapdom) ];
}

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        $c->stash->{failures}       = {};
        $c->stash->{reportlist_rga} = {};
        $c->stash->{reportlist_rgt} = {};
        $c->stash->{overview}       = undef;
        $c->stash->{report}         = $c->model('TestrunDB')->resultset('Report')->find($report_id);

        if (not $c->stash->{report}) {
                $c->response->body("No such report");
                $c->stash->{title} = "No such report";
                return;
        }

        if (not $c->stash->{report}->suite) {
                $c->response->body("No such testsuite with id: ". ($c->stash->{report}->suite_id // ""));
                $c->stash->{title} = "No such testsuite";
                return;
        }

        my $suite_name = $c->stash->{report}->suite->name;
        my $machine_name = $c->stash->{report}->machine_name;
        $c->stash->{title} = "Report $report_id: $suite_name @ $machine_name";

        my $util_report = Tapper::Reports::Web::Util::Report->new();

        if (my $rga = $c->stash->{report}->reportgrouparbitrary) {
                #my $rga_reports = $c->model('TestrunDB')->resultset('ReportgroupArbitrary')->search ({ arbitrary_id => $rga->arbitrary_id });
                my $rga_reports = $c->model('TestrunDB')->resultset('Report')->search
                    (
                     {
                      "reportgrouparbitrary.arbitrary_id" => $rga->arbitrary_id
                     },
                     {  order_by  => 'me.id desc',
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite'],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.id', 'suite.name', 'suite.type', 'suite.description' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_id', 'suite_name', 'suite_type', 'suite_description' ],
                     }
                    );
                $c->stash->{reportlist_rga} = $util_report->prepare_simple_reportlist($c,  $rga_reports);

                $rga_reports->reset;
                while (my $r = $rga_reports->next) {
                        if (my @report_failures = @{ $self->get_report_failures($r) }) {
                                $c->stash->{failures}->{$r->id}{name} = $r->suite->name;
                                $c->stash->{failures}->{$r->id}{machine_name} = $r->machine_name;
                                push @{$c->stash->{failures}->{$r->id}{failures}}, @report_failures;
                        }
                }
        }

        if (my $rgt = $c->stash->{report}->reportgrouptestrun) {
                #my $rgt_reports = $c->model('TestrunDB')->resultset('ReportgroupTestrun')->search ({ testrun_id => $rgt->testrun_id });
                my $rgt_reports = $c->model('TestrunDB')->resultset('Report')->search
                    (
                     {
                      "reportgrouptestrun.testrun_id" => $rgt->testrun_id
                     },
                     {  order_by  => 'me.id desc',
                        join      => [ 'reportgrouparbitrary',              'reportgrouptestrun', 'suite'],
                        '+select' => [ 'reportgrouparbitrary.arbitrary_id', 'reportgrouparbitrary.primaryreport', 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.name', 'suite.type', 'suite.description' ],
                        '+as'     => [ 'rga_id',                            'rga_primary',                        'rgt_id',                        'rgt_primary',                      'suite_name', 'suite_type', 'suite_description' ],
                     }
                    );
                $c->stash->{reportlist_rgt} = $util_report->prepare_simple_reportlist($c,  $rgt_reports);

                $rgt_reports->reset;
                while (my $r = $rgt_reports->next) {
                        if (my @report_failures = @{ $self->get_report_failures($r) }) {
                                $c->stash->{failures}->{$r->id}{name} = $r->suite->name;
                                $c->stash->{failures}->{$r->id}{machine_name} = $r->machine_name;
                                push @{$c->stash->{failures}->{$r->id}{failures}}, @report_failures;
                        }
                }

                my %cols = $rgt_reports->search({}, {rows => 1})->first->get_columns;
                my $testrun_id = $cols{rgt_id};
                my $testrun;
                eval {
                        $testrun    = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                };
                $c->stash->{overview} = $c->forward('/tapper/testruns/get_testrun_overview', [ $testrun ]);
        }

        my $tmp = [ grep {defined($_->{rgt_primary}) and $_->{rgt_primary} == 1} @{$c->stash->{reportlist_rgt}->{all_reports}} ]->[0]->{suite_name};
        my $report_data = {suite => $c->stash->{report}->suite ? $c->stash->{report}->suite->name : 'unknownsuite' ,
                           group_suite => $tmp};

        unless (my @report_failures = @{$c->stash->{failures}->{$c->stash->{report}->id}{failures} || []}) {
                $c->stash->{failures}->{$c->stash->{report}->id}{name} = $c->stash->{report}->suite->name;
                $c->stash->{failures}->{$c->stash->{report}->id}{machine_name} = $c->stash->{report}->machine_name;
                push @{$c->stash->{failures}->{$c->stash->{report}->id}{failures}}, @report_failures;
        }
        %{$c->stash->{metareport}} = $self->generate_metareport_link($report_data);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Reports::Id

=head2 generate_metareport_link

Generate config for showing metareport image associated to given report.

@param hash - config describing the relevant report

@return success - hash containing (url, img, alt, headline)
@return error   - empty list

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

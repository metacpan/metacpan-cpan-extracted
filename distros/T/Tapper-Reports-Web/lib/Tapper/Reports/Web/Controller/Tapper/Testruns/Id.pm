package Tapper::Reports::Web::Controller::Tapper::Testruns::Id;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Testruns::Id::VERSION = '5.0.15';
use 5.010;

use strict;
use warnings;
use Tapper::Model 'model';
use Tapper::Reports::Web::Util::Report;
use YAML::Syck;

use parent 'Tapper::Reports::Web::Controller::Base';


sub auto :Private
{
        my ( $self, $c ) = @_;

        $c->forward('/tapper/testruns/id/prepare_navi');
}


sub index :Path :Args(1)
{
        my ( $self, $c, $testrun_id ) = @_;

        $c->stash->{reportlist_rgt} = {};

        eval {
                $c->stash->{testrun} = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        };
        if ($@ or not $c->stash->{testrun}) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

        return unless $c->stash->{testrun}->testrun_scheduling;

        $c->stash->{time}     = $c->stash->{testrun}->starttime_testrun ? "started at ".$c->stash->{testrun}->starttime_testrun : $c->stash->{testrun}->testrun_scheduling->status." // ".($c->stash->{testrun}->starttime_earliest || '');
        $c->stash->{hostname} = $c->stash->{testrun}->testrun_scheduling->host ? $c->stash->{testrun}->testrun_scheduling->host->name : "unknown";

        $c->stash->{title} = "Testrun $testrun_id: ". $c->stash->{testrun}->topic_name . " @ ".$c->stash->{hostname};
        $c->stash->{overview} = $c->forward('/tapper/testruns/get_testrun_overview', [ $c->stash->{testrun} ]);

        my @preconditions_hash = map { $_->precondition_as_hash } $c->stash->{testrun}->ordered_preconditions;
        $YAML::Syck::SortKeys  = 1;
        $c->stash->{precondition_string} = YAML::Syck::Dump(@preconditions_hash);

        my $rgt_reports = $c->model('TestrunDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.testrun_id" => $testrun_id
           },
           {  order_by  => 'me.id desc',
              join      => [ 'reportgrouptestrun', 'suite'],
              '+select' => [ 'reportgrouptestrun.testrun_id', 'reportgrouptestrun.primaryreport', 'suite.name', 'suite.type', 'suite.description' ],
              '+as'     => [ 'rgt_id',                        'rgt_primary',                      'suite_name', 'suite_type', 'suite_description' ],
           }
          );
        my $util_report = Tapper::Reports::Web::Util::Report->new();

        $c->stash->{reportlist_rgt} = $util_report->prepare_simple_reportlist($c,  $rgt_reports);
        $c->stash->{report} = $c->model('TestrunDB')->resultset('Report')->search
          (
           {
            "reportgrouptestrun.primaryreport" => 1,
           },
           {
            join => [ 'reportgrouptestrun', ]
           }
           );
}

sub prepare_navi : Private
{
        my ( $self, $c, $testrun_id ) = @_;

        my $tr;
        my $job;
        my $status = 'undefined';
        $tr     = $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        $job    = $tr->testrun_scheduling if $tr;
        $status = $job->status if $job;

        $c->stash->{navi} =[
                            {
                             title  => "Testruns by date",
                             href   => "/tapper/testruns/days/2",
                             active => 0,
                             subnavi => [
                                         {
                                          title  => "today",
                                          href   => "/tapper/testruns/days/1",
                                         },
                                         {
                                          title  => "1 week",
                                          href   => "/tapper/testruns/days/7",
                                         },
                                         {
                                          title  => "2 weeks",
                                          href   => "/tapper/testruns/days/14",
                                         },
                                         {
                                          title  => "3 weeks",
                                          href   => "/tapper/testruns/days/21",
                                         },
                                         {
                                          title  => "1 month",
                                          href   => "/tapper/testruns/days/30",
                                         },
                                         {
                                          title  => "2 months",
                                          href   => "/tapper/testruns/days/60",
                                         },
                                        ],
                            },
                            {
                             title  => "Control",
                             href   => "",
                             active => 0,
                             subnavi => [
                               ($status eq 'finished'
                                  ? {
                                    title  => "Rerun",
                                    href   => "/tapper/testruns/$testrun_id/rerun",
                                    confirm => 'Do you really want to RERUN this testrun?',
                                  }
                                  : ()),
                               ($status =~ /^(running|schedule|prepare)$/
                                  ? {
                                    title  => "Cancel",
                                    href   => "/tapper/testruns/$testrun_id/cancel",
                                    confirm => 'Do you really want to CANCEL this testrun?',
                                  }
                                  : ()),
                               ($status eq 'schedule'
                                  ? {
                                    title  => "Unschedule",
                                    href   => "/tapper/testruns/$testrun_id/pause",
                                    confirm => 'Do you really want to UNSCHEDULE this testrun?',
                                  }
                                  : ()),
                               ($status eq 'prepare'
                                  ? {
                                    title  => "Reschedule",
                                    href   => "/tapper/testruns/$testrun_id/continue",
                                    confirm => 'Do you really want to RESCHEDULE this testrun?',
                                  }
                                  : ()),
                               {
                                 title  => "Create new testrun",
                                 href   => "/tapper/testruns/create",
                               },
                             ],
                            },
                           ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testruns::Id

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

package Tapper::Reports::Web::Util::Testrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::Testrun::VERSION = '5.0.13';
use Moose;
use Tapper::Model 'model';

use common::sense;

extends 'Tapper::Reports::Web::Util';



sub prepare_testrunlist
{
        my ( $self, $testruns ) = @_;

        my @testruns;
        foreach my $testrun ($testruns->all)
        {
                my $testrun_report = model('ReportsDB')->resultset('ReportgroupTestrunStats')->search({testrun_id => $testrun->id}, {rows => 1})->first;
                my ($primary_report, $suite_name, $updated_at, $primary_report_id);

                if ($testrun_report) {
                        $primary_report = $testrun_report->reportgrouptestruns->search({primaryreport => 1}, {rows => 1})->first;
                        $primary_report = $testrun_report->reportgrouptestruns->search({}, {rows => 1})->first unless $primary_report; # link to any report if no primary

                        eval{ # prevent dereferencing to undefined db links
                                if ($primary_report) {
                                        $suite_name        = $primary_report->report->suite->name;
                                        $updated_at        = $primary_report->report->updated_at || $primary_report->created_at;
                                        $primary_report_id = $primary_report->report->id;
                                }
                        };
                }


                my ($hostname, $status);
                if ($testrun->testrun_scheduling) {
                        if ($testrun->testrun_scheduling->host) {
                                $hostname = $testrun->testrun_scheduling->host->name;
                        } else {
                                $hostname = $testrun->testrun_scheduling->status eq 'finished' ?
                                  'Host deleted' :
                                    'No host assigned';

                        }
                        $status   = $testrun->testrun_scheduling->status;
                }

                my $tr = {
                          testrun_id            => $testrun->id,
                          success_ratio         => $testrun_report ? $testrun_report->success_ratio : 0,
                          primary_report_id     => $primary_report_id,
                          topic_name            => $testrun->topic_name,
                          machine_name          => $hostname   || 'unknownmachine',
                          status                => $status     || 'unknown status',
                          started_at            => $testrun->starttime_testrun,
                          created_at            => $testrun->created_at,
                          updated_at            => $updated_at || $testrun->updated_at,
                          owner                 => $testrun->owner->login || 'unknown user' ,
                         };
                push @testruns, $tr;
        }
        return  \@testruns;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Util::Testrun

=head2 prepare_testrunlist

For each of the given testruns generate a hash describing the
testrun. This hash is used to display the testrun in the template.

hash contains:
* primary_report_id
* success_ratio
* testrun_id
* suite_name
* host_name
* status
* created_at
* updated_at

@param DBIC resultset - testruns

@return array ref - list of hash refs describing the testruns

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

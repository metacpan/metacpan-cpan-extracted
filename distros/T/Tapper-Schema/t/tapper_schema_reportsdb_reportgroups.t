#! /usr/bin/env perl

use lib '.';

use strict;
use warnings;

use Data::Dumper;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Test::More;
use Test::Deep;
use Scalar::Util;

BEGIN {
        use_ok( 'Tapper::Schema::TestrunDB' );
}

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/reportgroups.yml' );
# -----------------------------------------------------------------------------------------------------------------

is( testrundb_schema->resultset('ReportgroupTestrun')->count,   3, "reportgrouptestrun count" );
is( testrundb_schema->resultset('ReportgroupArbitrary')->count, 3, "reportgrouparbitrary count" );

# find report
my $report = testrundb_schema->resultset('Report')->find(23);
like($report->tap->tap, qr/OK 2 bar CCC/ms, "found report");

# find according report group (grouped by testrun)
my $rgt = $report->reportgrouptestrun;
ok(defined $rgt, "has according reportgroup testrun");

# find according report group stats -- should not exist yet
my $rgt_stats = testrundb_schema->resultset('ReportgroupTestrunStats')->find($rgt->testrun_id);
is($rgt_stats, undef, "no reportgroup stats yet");

# re-create report group stats
$rgt_stats = testrundb_schema->resultset('ReportgroupTestrunStats')->new({ testrun_id => $rgt->testrun_id });
$rgt_stats->insert;
is($rgt_stats->testrun_id, 753, "reportgroup stats created");

is($rgt_stats->testrun_id, 753, "reportgroup stats created");

$rgt_stats = testrundb_schema->resultset('ReportgroupTestrunStats')->new({ testrun_id => $rgt->testrun_id });

$rgt = $rgt_stats->reportgrouptestruns;
cmp_bag([ map { $_->report_id } $rgt->all], [21, 22, 23], "reports via rgt_stats.reportgrouptestruns");
#diag "rgt testruns: ", Dumper([ map { $_->report_id } $rgt->all]);

my $reports = $rgt->first->groupreports;
cmp_bag([ map { $_->id } $reports->all ], [21, 22, 23], "reports via rgt.first.groupreports");
#diag "reports: ", Dumper([ map { $_->id } $reports->all]);

$reports = $rgt->groupreports;
cmp_bag([ map { $_->id } $reports->all ], [21, 22, 23], "reports via rgt.groupreports");
#diag "reports: ", Dumper([ map { $_->id } $reports->all]);

$reports = $rgt_stats->groupreports;
cmp_bag([ map { $_->id } $reports->all ], [21, 22, 23], "reports via rgt_stats.groupreports");
#diag "rgt testruns: ",Dumper([ map { $_->id } $reports->all]);

# is($rgt_stats->reports->reportgrouptestruns->search({}), 753, "reportgroup stats created");

# use Tapper::Reports::Receiver;
# my $receiver = Tapper::Reports::Receiver->new;
# while (my $r = $reports->next) {
#         $receiver->refresh_db_report($r->id);
# }

# $rgt_stats->update_failed_passed;
# $rgt_stats->update;
# is( $rgt_stats->total, 12, "rgt.total");

done_testing;

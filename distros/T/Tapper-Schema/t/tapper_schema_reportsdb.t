#! /usr/bin/env perl

use lib '.';

use strict;
use warnings;

use Data::Dumper;
use Compress::Bzip2;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Test::More 0.88;
use Test::Deep;
use Scalar::Util;
use Tapper::Config;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

# ok( testrundb_schema->get_db_version, "schema is versioned" );
# diag testrundb_schema->get_db_version;

is( testrundb_schema->resultset('Report')->count, 3,  "report count" );

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/reportsection.yml' );
# -----------------------------------------------------------------------------------------------------------------

is( testrundb_schema->resultset('ReportSection')->count, 8,  "reportsection count" );

my @reportsections = testrundb_schema->resultset('ReportSection')->search({report_id => 21})->all;
is( scalar @reportsections, 8,  "reportsection count" );

is( $reportsections[0]->some_meta_available, 1, "section - some meta available 0");
is( $reportsections[1]->some_meta_available, 1, "section - some meta available 1");
is( $reportsections[2]->some_meta_available, 1, "section - some meta available 2");
is( $reportsections[3]->some_meta_available, 1, "section - some meta available 3");
is( $reportsections[4]->some_meta_available, 1, "section - some meta available 4");
is( $reportsections[5]->some_meta_available, 0, "section - some meta available 5");
is( $reportsections[6]->some_meta_available, 1, "section - some meta available 6");
is( $reportsections[7]->some_meta_available, 1, "section - some meta available 7");

is( testrundb_schema->resultset('Report')->find(20)->some_meta_available, 0, "report - some_meta_available 0");
is( testrundb_schema->resultset('Report')->find(21)->some_meta_available, 1, "report - some_meta_available 1");


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/reportgroups.yml' );
# -----------------------------------------------------------------------------------------------------------------

is( testrundb_schema->resultset('ReportgroupTestrun')->count,   3, "reportgrouptestrun count" );
is( testrundb_schema->resultset('ReportgroupArbitrary')->count, 3, "reportgrouparbitrary count" );

my $report = testrundb_schema->resultset('Report')->find(24);
like($report->tap->tap, qr/OK 2 bar DDD/ms, "found report");
my $reportgroup_arbitrary = $report->reportgrouparbitrary;
ok(defined $reportgroup_arbitrary, "has according reportgroup arbitrary");

$report = testrundb_schema->resultset('Report')->find(23);
like($report->tap->tap, qr/OK 2 bar CCC/ms, "found report");
my $reportgroup_testrun = $report->reportgrouptestrun;
ok(defined $reportgroup_testrun, "has according reportgroup testrun");

unlike($report->tap->tapdom, qr/\$VAR1/, "no tapdom yet");
my $tapdom = $report->get_cached_tapdom;
is(Scalar::Util::reftype($tapdom), "ARRAY", "got tapdom");

SKIP: {
    skip "TAP::DOM caching is disabled in config", 2 unless Tapper::Config->subconfig->{cache_tapdom_in_db};
# get it again
$report = testrundb_schema->resultset('Report')->find(23);
like($report->tap->tapdom, qr/\$VAR1/, "tapdom created on demand looks like Data::Dumper string");
#diag "tapdom1: ".$report->tap->tapdom;
my $VAR1;
eval $report->tap->tapdom;
my $tapdom2 = $VAR1;
#diag "tapdom2: ".Dumper($tapdom2);
my $tapdom1 = $tapdom;

# don't fiddle with nested qr/(?-xism(?-xism))/ issues
$tapdom1->[0]{section}{'section-000'}{tap}{tapdom_config}{ignorelines} = 'ignore';
$tapdom2->[0]{section}{'section-000'}{tap}{tapdom_config}{ignorelines} = 'ignore';
cmp_bag($tapdom2, $tapdom1, "stored tapdom keeps constant");
}

# ===== file compression =====
my $file = testrundb_schema->resultset('ReportFile')->new({
                                                           report_id => 21,
                                                           filename  => 'affe',
                                                           filecontent => 'zomtec',
                                                          }
                                                         );
$file->insert;
my $unfiltered = $file->get_column('filecontent');

is($file->filecontent, 'zomtec', 'Content of file');
is($file->is_compressed, 1, 'File is compressed');
is (memBunzip($unfiltered), 'zomtec', 'Unfiltered content of file bunzipped');
isnt($unfiltered, 'zomtec', 'Unfiltered content of file');
diag testrundb_schema->resultset('ReportFile')->first->filecontent;

$file = testrundb_schema->resultset('ReportFile')->new({
                                                        report_id => 21,
                                                        filename  => 'affe',
                                                        filecontent => '',
                                                       }
                                                      );
$file->insert;
$unfiltered = $file->get_column('filecontent');
is($file->filecontent, '', 'Content of empty file');
is($file->is_compressed, 0, 'Empty file is uncompressed');
is($unfiltered, '', 'Unfiltered content of empty file');

done_testing;

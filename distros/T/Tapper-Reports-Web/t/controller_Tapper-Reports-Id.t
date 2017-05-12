use strict;
use warnings;
use Data::Dumper;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

use Test::More;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------


BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Reports::Id' }

#ok( request('/tapper/reports/id')->is_success, 'Request should succeed' );

#my $controller = Tapper::Reports::Web::Controller::Tapper::Reports::Id->new;
my $report     = testrundb_schema->resultset('Report')->find(23);
unlike($report->tap->tapdom, qr/\$VAR1/, "no tapdom yet");
my $tapdom = $report->get_cached_tapdom;
is(Scalar::Util::reftype($tapdom), "ARRAY", "got tapdom");

my $failures   = Tapper::Reports::Web::Controller::Tapper::Reports::Id::get_report_failures(undef, $report);

# diag Dumper($failures);

is($failures->[0]{description}, "- fink", "found failing test");

done_testing;

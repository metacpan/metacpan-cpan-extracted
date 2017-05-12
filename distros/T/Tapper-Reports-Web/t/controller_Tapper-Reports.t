use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

BEGIN { use_ok q#Catalyst::Test#, 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Reports' }

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $url;
my $req;
my $success;

$url = 'tapper/reports';
$req = request($url);
$success = $req->is_success;
diag Dumper($req) if not $success;
ok( $success, "Request $url should succeed");

$url = 'tapper/reports?report_date=2011-08-05';
$req = request($url);
$success = $req->is_success;
diag Dumper($req) if not $success;
ok( $success, "Request $url should succeed");

done_testing;

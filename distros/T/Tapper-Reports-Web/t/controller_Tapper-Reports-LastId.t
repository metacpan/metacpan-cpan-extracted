use strict;
use warnings;
use Data::Dumper;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

use Test::More;

# -----------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------


BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Reports::Info' }

ok( request('/tapper/reports/info/lastid')->is_success, 'Request should succeed' );
is(     get('/tapper/reports/info/firstid'), 21, 'correct firstid' );
is(     get('/tapper/reports/info/lastid'),  23, 'correct lastid' );

done_testing;

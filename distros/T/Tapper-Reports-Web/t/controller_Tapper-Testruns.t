use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper' }

# -----------------------------------------------------------------------------------------------------------------
# construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------

ok( request('/tapper')->is_success, 'Request 1 should succeed' );
ok( request('/tapper/testruns/id/1')->is_success, 'Request 2 should succeed' );
ok( request('/tapper/testruns/create')->is_success, 'Request 3 should succeed' );

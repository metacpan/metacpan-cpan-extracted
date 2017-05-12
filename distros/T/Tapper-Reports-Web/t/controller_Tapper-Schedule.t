use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Schedule' }

ok( request('/tapper/schedule')->is_success, 'Request should succeed' );



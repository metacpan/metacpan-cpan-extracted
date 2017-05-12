use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'MyApp' }

ok( request('/login')->is_success, 'Request should succeed' );


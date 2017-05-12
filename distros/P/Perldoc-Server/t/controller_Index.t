use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Catalyst::Test', 'Perldoc::Server' }
BEGIN { use_ok 'Perldoc::Server::Controller::Index' }

ok( request('/index/modules/A')->is_success, 'Request should succeed' );
ok( request('/index/functions')->is_success, 'Request should succeed' );



use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Perldoc::Server' }
BEGIN { use_ok 'Perldoc::Server::Controller::Source' }

ok( request('/source')->is_success, 'Request should succeed' );



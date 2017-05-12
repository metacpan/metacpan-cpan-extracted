use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Perldoc::Server' }
BEGIN { use_ok 'Perldoc::Server::Controller::Ajax::PerlSyntax' }

ok( request('/ajax/perlsyntax')->is_success, 'Request should succeed' );



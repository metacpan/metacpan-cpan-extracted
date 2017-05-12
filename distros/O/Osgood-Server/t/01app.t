use strict;
use warnings;
use Test::More tests => 2;

# $ENV{CATALYST_DEBUG}=0;
$ENV{CATALYST_CONFIG}='t/var/osgood_server.yml';

use_ok 'Catalyst::Test', 'Osgood::Server';

ok( request('/')->is_success, 'Request should succeed' );

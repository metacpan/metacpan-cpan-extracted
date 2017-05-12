use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
use_ok( 'MooseX::Daemonize' );
}

diag( "Testing MooseX::Daemonize $MooseX::Daemonize::VERSION" );

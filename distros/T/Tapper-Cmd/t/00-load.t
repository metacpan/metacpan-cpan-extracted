#!perl

use Test::More tests => 6;

BEGIN {
        use_ok( 'Tapper::Cmd' );
        use_ok( 'Tapper::Cmd::Testrun' );
        use_ok( 'Tapper::Cmd::Testplan' );
        use_ok( 'Tapper::Cmd::Precondition' );
        use_ok( 'Tapper::Cmd::Queue' );
        use_ok( 'Tapper::Cmd::Cobbler' );
}

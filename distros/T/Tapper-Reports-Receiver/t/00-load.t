#!perl

use Test::More tests => 1;

use Class::C3;
use MRO::Compat;

BEGIN {
        use_ok( 'Tapper::Reports::Receiver' );
}

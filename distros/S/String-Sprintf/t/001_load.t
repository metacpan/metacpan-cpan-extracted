# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 2;

BEGIN { use_ok( 'String::Sprintf' ); }

my $formatter = String::Sprintf->formatter ();
isa_ok ($formatter, 'String::Sprintf');


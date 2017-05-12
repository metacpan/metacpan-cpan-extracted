# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Spork::Template::Mason' ); }

my $object = Spork::Template::Mason->new ();
isa_ok ($object, 'Spork::Template::Mason');



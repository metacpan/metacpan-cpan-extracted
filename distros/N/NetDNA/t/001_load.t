# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'NetDNA' ); }

my $object = NetDNA->new ('jdorfman','1234','1234');
isa_ok ($object, 'NetDNA');



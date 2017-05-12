# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Safari' ); }

my $object = Net::Safari->new ();
isa_ok ($object, 'Net::Safari');



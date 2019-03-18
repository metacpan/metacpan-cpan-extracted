# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Siffra::Transfers' ); }

my $object = Siffra::Transfers->new();
isa_ok( $object, 'Siffra::Transfers' );
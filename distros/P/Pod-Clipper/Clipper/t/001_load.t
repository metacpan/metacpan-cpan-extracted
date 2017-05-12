# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Pod::Clipper' ); }

my $object = Pod::Clipper->new({ data => "" });
isa_ok ($object, 'Pod::Clipper');



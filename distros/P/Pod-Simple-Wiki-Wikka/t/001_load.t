# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Pod::Simple::Wiki::Wikka' ); }

my $object = Pod::Simple::Wiki::Wikka->new ();
isa_ok ($object, 'Pod::Simple::Wiki::Wikka');



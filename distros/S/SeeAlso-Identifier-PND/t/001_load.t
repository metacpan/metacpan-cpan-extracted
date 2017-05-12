# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 4;

BEGIN { use_ok( 'SeeAlso::Identifier::PND' ); }

my $object = SeeAlso::Identifier::PND->new ();
isa_ok ($object, 'SeeAlso::Identifier::PND');
isa_ok ($object, 'SeeAlso::Identifier::GND');
isa_ok ($object, 'SeeAlso::Identifier');



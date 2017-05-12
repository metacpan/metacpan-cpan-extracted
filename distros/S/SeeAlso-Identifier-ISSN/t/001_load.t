# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'SeeAlso::Identifier::ISSN' ); }

my $object = SeeAlso::Identifier::ISSN->new ();
isa_ok ($object, 'SeeAlso::Identifier::ISSN');



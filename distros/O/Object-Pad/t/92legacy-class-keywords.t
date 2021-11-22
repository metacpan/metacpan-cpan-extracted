#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   method rolem { "ARole" }
}

class AClass {
   method classm { "AClass" }
}

class BClass extends AClass implements ARole {}

{
   my $obj = BClass->new;
   isa_ok( $obj, "BClass", '$obj' );

   is( $obj->rolem, "ARole", 'BClass has ->rolem' );
   is( $obj->classm, "AClass", 'BClass has ->classm' );
}

class CClass isa AClass does ARole {}

{
   my $obj = CClass->new;
   isa_ok( $obj, "CClass", '$obj' );

   is( $obj->rolem, "ARole", 'CClass has ->rolem' );
   is( $obj->classm, "AClass", 'CClass has ->classm' );
}

done_testing;

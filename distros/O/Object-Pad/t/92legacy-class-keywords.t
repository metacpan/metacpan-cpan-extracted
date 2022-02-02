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

my $warnings = "";
BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }

class BClass extends AClass implements ARole {}

{
   my $obj = BClass->new;
   isa_ok( $obj, "BClass", '$obj' );

   is( $obj->rolem, "ARole", 'BClass has ->rolem' );
   is( $obj->classm, "AClass", 'BClass has ->classm' );
}

BEGIN {
   like( $warnings, qr/^'extends' is deprecated; use :isa instead /m,
      'extends keyword provokes deprecation warnings' );
   like( $warnings, qr/^'implements' is deprecated; use :does instead /m,
      'implements keyword provokes deprecation warnings' );
   undef $SIG{__WARN__};
}

class CClass isa AClass does ARole {}

{
   my $obj = CClass->new;
   isa_ok( $obj, "CClass", '$obj' );

   is( $obj->rolem, "ARole", 'CClass has ->rolem' );
   is( $obj->classm, "AClass", 'CClass has ->classm' );
}

done_testing;

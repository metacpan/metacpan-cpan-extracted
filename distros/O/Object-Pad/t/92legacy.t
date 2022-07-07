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
   like( $warnings, qr/^'extends' modifier keyword is deprecated; use :isa\(\) attribute instead at /m,
      'extends keyword provokes deprecation warnings' );
   like( $warnings, qr/^'implements' modifier keyword is deprecated; use :does\(\) attribute instead /m,
      'implements keyword provokes deprecation warnings' );

   undef $warnings;
}

class CClass isa AClass does ARole {}

{
   my $obj = CClass->new;
   isa_ok( $obj, "CClass", '$obj' );

   is( $obj->rolem, "ARole", 'CClass has ->rolem' );
   is( $obj->classm, "AClass", 'CClass has ->classm' );
}

BEGIN {
   like( $warnings, qr/^'isa' modifier keyword is deprecated; use :isa\(\) attribute instead at /m,
      'extends keyword provokes deprecation warnings' );
   like( $warnings, qr/^'does' modifier keyword is deprecated; use :does\(\) attribute instead /m,
      'implements keyword provokes deprecation warnings' );

   undef $warnings;
}

role DRole { requires mmethod; }

BEGIN {
   like( $warnings, qr/^'requires' is now discouraged; use an empty 'method NAME;' declaration instead at /m,
      'requires keyword provokes discouraged warning' );
}

BEGIN {
   undef $SIG{__WARN__};
}

done_testing;

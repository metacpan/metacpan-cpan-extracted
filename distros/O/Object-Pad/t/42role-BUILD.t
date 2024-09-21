#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

my @BUILD;
my @ADJUST;

role ARole {
  BUILD { push @BUILD, "ARole" }
  ADJUST { push @ADJUST, "ARole" }
}

class AClass {
   apply ARole;

   BUILD { push @BUILD, "AClass" }
   ADJUST { push @ADJUST, "AClass" }
}

{
   undef @BUILD;
   undef @ADJUST;

   AClass->new;

   is( \@BUILD, [qw( ARole AClass )],
      'Roles are built before their implementing classes' );

   is( \@ADJUST, [qw( ARole AClass )],
      'Roles are adjusted before their implementing classes' );
}

class BClass {
   inherit AClass;
   apply ARole;

   BUILD { push @BUILD, "BClass" }
}

{
   undef @BUILD;

   BClass->new;

   is( \@BUILD, [qw( ARole AClass BClass )],
      'Roles are built once only even if implemented multiple times' );
}

# RT154494
{
   use Object::Pad ':experimental(composed_adjust)';

   role RT154494Role { }
   pass( 'Managed to compile a role under :experimental(composed_adjust)' );
}

done_testing;

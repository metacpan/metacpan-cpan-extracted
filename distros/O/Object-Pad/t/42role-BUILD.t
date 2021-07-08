#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

my @BUILD;
my @ADJUST;

role ARole {
  BUILD { push @BUILD, "ARole" }
  ADJUST { push @ADJUST, "ARole" }
}

class AClass does ARole {
  BUILD { push @BUILD, "AClass" }
  ADJUST { push @ADJUST, "AClass" }
}

{
   undef @BUILD;
   undef @ADJUST;

   AClass->new;

   is_deeply( \@BUILD, [qw( ARole AClass )],
      'Roles are built before their implementing classes' );

   is_deeply( \@ADJUST, [qw( ARole AClass )],
      'Roles are adjusted before their implementing classes' );
}

class BClass isa AClass does ARole {
  BUILD { push @BUILD, "BClass" }
}

{
   undef @BUILD;

   BClass->new;

   is_deeply( \@BUILD, [qw( ARole AClass BClass )],
      'Roles are built once only even if implemented multiple times' );
}

done_testing;

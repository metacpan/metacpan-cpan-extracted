#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

my @BUILD;

role ARole {
  BUILD { push @BUILD, "ARole" }
}

class AClass implements ARole {
  BUILD { push @BUILD, "AClass" }
}

{
   undef @BUILD;

   AClass->new;

   is_deeply( \@BUILD, [qw( ARole AClass )],
      'Roles are built before their implementing classes' );
}

class BClass extends AClass implements ARole {
  BUILD { push @BUILD, "BClass" }
}

{
   undef @BUILD;

   BClass->new;

   is_deeply( \@BUILD, [qw( ARole AClass BClass )],
      'Roles are built once only even if implemented multiple times' );
}

done_testing;

#!/usr/bin/perl

use v5.18;
use warnings;
use utf8;

use Test2::V0;

use Object::Pad 0.800 ':experimental(apply_phaser)';

my $cmop_during_APPLY;

role ARole {
   APPLY {
      my ( $cmop ) = @_;
      $cmop_during_APPLY = $cmop;
   }
}

{
   class AClass {
      apply ARole;
   }

   my $got_cmop;
   BEGIN { $got_cmop = $cmop_during_APPLY; undef $cmop_during_APPLY; }

   ok( $got_cmop, 'saw class MOP during compiletime of class' );
   is( $got_cmop->name, "AClass", 'class MOP ->name' );
}

role BRole {
   apply ARole;
}

{
   my $got_cmop;
   BEGIN { $got_cmop = $cmop_during_APPLY; undef $cmop_during_APPLY; }

   ok( !defined $got_cmop, 'APPLY phaser does not run for role-in-role' );
}

{
   class BClass {
      apply BRole;
   }

   my $got_cmop;
   BEGIN { $got_cmop = $cmop_during_APPLY; undef $cmop_during_APPLY; }

   ok( $got_cmop, 'saw class MOP during compiletime of class' );
   is( $got_cmop->name, "BClass", 'class MOP ->name' );
}

done_testing;

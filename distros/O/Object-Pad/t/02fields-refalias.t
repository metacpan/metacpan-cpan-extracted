#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Test2::Require::Perl 'v5.22'; # refaliasing

use Object::Pad 0.800;

class FieldRefalias
{
   # Perl 5.22 and above have experimental.pm anyway
   use experimental qw( refaliasing );

   field %x :reader;

   method refalias
   {
      # this doesn't modify the field itself, just the
      # lexical slot in the method's pad
      \%x = \%ENV;
      $self;
   }
}

{
   my $o = FieldRefalias->new;
   $o->refalias;
   # the reference to $x would crash/assert
   $o->x;
   pass( 'Code runs with refalias to field' );
}

done_testing;

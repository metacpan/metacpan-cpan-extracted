#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class AClass {
   method classm { "AClass" }
}

my $warnings = "";
BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }

role DRole { requires mmethod; }

BEGIN {
   like( $warnings, qr/^'requires' is now discouraged; use an empty 'method NAME;' declaration instead at /m,
      'requires keyword provokes discouraged warning' );

   undef $warnings;
}

{
   my @called;
   my $paramsref;

   class EClass {
      ADJUST {
         push @called, "ADJUST";
      }

      ADJUSTPARAMS {
         my ( $href ) = @_;
         push @called, "ADJUSTPARAMS";
         $paramsref = $href;
      }

      ADJUST {
         push @called, "ADJUST";
      }
   }

   EClass->new( key => "val" );
   is( \@called, [qw( ADJUST ADJUSTPARAMS ADJUST )], 'ADJUST and ADJUSTPARAMS invoked together' );
   is( $paramsref, { key => "val" }, 'ADJUSTPARAMS received HASHref' );
}

my $ADJUST_LINE;
class FClass {
   ADJUST {
      BEGIN { $ADJUST_LINE = __LINE__+1 }
      my @d0 = @_;
      my $d1 = shift;
      my $d2 = shift @_;
      my $d3 = $_[0];
   }
}

BEGIN {
   my $line0 = $ADJUST_LINE;
   like( $warnings, qr/^Use of \@_ is deprecated in ADJUST at \S+ line $line0\./m,
      '@_ in ADJUST prints deprecation warning' );

   my $line1 = $ADJUST_LINE+1;
   like( $warnings, qr/^Implicit use of \@_ in shift is deprecated in ADJUST at \S+ line $line1\./m,
      'shift in ADJUST prints deprecation warning' );

   my $line2 = $ADJUST_LINE+2;
   like( $warnings, qr/^Use of \@_ is deprecated in ADJUST at \S+ line $line2\./m,
      'shift @_ in ADJUST prints deprecation warning' );

   my $line3 = $ADJUST_LINE+3;
   like( $warnings, qr/^Use of \@_ is deprecated in ADJUST at \S+ line $line3\./m,
      '$_[0] in ADJUST prints deprecation warning' );

   undef $warnings;
}

BEGIN {
   undef $SIG{__WARN__};
}

done_testing;

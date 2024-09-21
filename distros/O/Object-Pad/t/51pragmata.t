#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad;  # no version

{
   no strict;

   $abc = $abc; # to demostrate strict is off
   ok( !eval <<'EOPERL',
      class TestStrict {
         sub x { $def = $def; }
      }
EOPERL
      'class scope implies use strict' );
   like( $@, qr/^Global symbol "\$def" requires explicit package name /,
      'message from failure of use strict' );
}

{
   my $warnings = "";
   local $SIG{__WARN__} = sub {
      $warnings .= join "", @_;
   };

   ok( defined eval <<'EOPERL',
      no warnings;
      class TestWarnings {
         my $str = undef . "boo";
      }
EOPERL
      'class scope compiles for warnings test' );
   like( $warnings, qr/^Use of uninitialized value in concatenation \(\.\) or string at /,
      'warning from uninitialized value test' );
}

SKIP: {
   # TODO: Work out why and fix it
   skip "'no indirect' doesn't appear to work on this perl", 2 if $] < 5.020;

   my $warnings = "";
   local $SIG{__WARN__} = sub {
      $warnings .= join "", @_;
   };

   ok( !eval <<'EOPERL',
      class TestIndirect {
         sub x { foo Test->new(1,2,3) }
      }

      1;
EOPERL
      'class scope implies no indirect' );
   my $e = $@;

   if( $] >= 5.031009 ) {
      # On perl 5.31.9 onwards we use core's  no feature 'indirect' which has
      #   different error semantics. It gives a generic "syntax error" plus
      #   warnings
      like( $warnings,
         qr/^Bareword found where operator expected (?:\(Do you need to predeclare "foo"\?\) )?at \(eval /,
         'warnings from failure of no feature "indirect"' );
      like( $e,
         qr/^syntax error at \(eval /,
         'error result from failure of no feature "indirect"' );
   }
   else {
      like( $e,
         qr/^Indirect call of method "foo" on object "Test" /,
         'message from failure of no indirect' );
   }
}

done_testing;

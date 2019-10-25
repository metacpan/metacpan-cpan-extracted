#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

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

SKIP: {
   # TODO: Work out why and fix it
   skip "'no indirect' doesn't appear to work on this perl", 2 if $] < 5.020;

   ok( !eval <<'EOPERL',
      class TestIndirect {
         sub x { new Test(1,2,3) }
      }

      1;
EOPERL
      'class scope implies no indirect' );

   like( $@, qr/^Indirect call of method "new" on object "Test" /,
      'message form failure of no indirect' );
}

done_testing;

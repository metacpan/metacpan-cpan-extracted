#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Test::MemoryGrowth is not available" unless
      defined eval { require Test::MemoryGrowth };

   Test::MemoryGrowth->import;
}

use Object::Pad 0.800;

# RT132332
{
   class Example {
       # Needs at least one field member to trigger failures
       field $thing;
       # ... and we need to refer to it in a method as well
       ADJUST { $thing }
   }

   no_growth { Example->new };
}

{
   class WithContainerFields {
      field @array;
      field %hash;

      ADJUST {
         @array = ();
         %hash  = ();
      }
   }

   no_growth { WithContainerFields->new };
}

{
   use Object::Pad ':experimental(adjust_params)';

   class WithAdjustParams {
      field $_x;
      ADJUST :params ( :$x ) { $_x = $x; }
   }

   no_growth { WithAdjustParams->new( x => "the X value" ) }
      'named constructor param does not leak';
}

{
   class WithHashKeys :repr(keys) {
      field $f = "value";
      method x { $f = $f; }
   }

   no_growth { WithHashKeys->new->x }
      ':repr(keys) does not leak';
}

done_testing;

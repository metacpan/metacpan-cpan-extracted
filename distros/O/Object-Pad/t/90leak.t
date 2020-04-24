#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Test::MemoryGrowth is not available" unless
      defined eval { require Test::MemoryGrowth };

   Test::MemoryGrowth->import;
}

use Object::Pad;

# RT132332
{
   class Example {
       # Needs at least one field member to trigger failures
       has $thing;
       # ... and we need to refer to it in a method as well
       method BUILD { $thing }
   }

   no_growth { Example->new };
}

{
   class WithContainerSlots {
      has @array;
      has %hash;

      method BUILD {
         @array = ();
         %hash  = ();
      }
   }

   no_growth { WithContainerSlots->new };
}

done_testing;

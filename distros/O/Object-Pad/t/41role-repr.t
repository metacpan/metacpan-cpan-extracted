#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

role ARole {
   method one { return 1 }
}

package Base::HASH {
   sub new { bless {}, shift }
}

class Derived::HASH {
   inherit Base::HASH;
   apply ARole;
}

{
   my $obj = Derived::HASH->new;

   is( $obj->one, 1, 'Derived::HASH has a ->one method' );
}

package Base::ARRAY {
   sub new { bless [], shift }
}

class Derived::ARRAY {
   inherit Base::ARRAY;
   apply ARole;
}

{
   my $obj = Derived::ARRAY->new;

   is( $obj->one, 1, 'Derived::ARRAY has a ->one method' );
}

done_testing;

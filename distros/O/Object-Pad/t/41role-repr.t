#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   method one { return 1 }
}

package Base::HASH {
   sub new { bless {}, shift }
}

class Derived::HASH isa Base::HASH does ARole {
}

{
   my $obj = Derived::HASH->new;

   is( $obj->one, 1, 'Derived::HASH has a ->one method' );
}

package Base::ARRAY {
   sub new { bless [], shift }
}

class Derived::ARRAY isa Base::ARRAY does ARole {
}

{
   my $obj = Derived::ARRAY->new;

   is( $obj->one, 1, 'Derived::ARRAY has a ->one method' );
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   method one { return 1 }
}

package Base::HASH {
   sub new { bless {}, shift }
}

class Derived::HASH extends Base::HASH implements ARole {
}

{
   my $obj = Derived::HASH->new;

   is( $obj->one, 1, 'Derived::HASH has a ->one method' );
}

package Base::ARRAY {
   sub new { bless [], shift }
}

class Derived::ARRAY extends Base::ARRAY implements ARole {
}

{
   my $obj = Derived::ARRAY->new;

   is( $obj->one, 1, 'Derived::ARRAY has a ->one method' );
}

done_testing;

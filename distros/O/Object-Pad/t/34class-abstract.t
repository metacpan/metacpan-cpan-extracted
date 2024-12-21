#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class Base :abstract {
   field $f :param;

   method m1;

   method m2 { return $f; }
}

like( dies { Base->new },
   qr/^Cannot directly construct an instance of abstract class 'Base' at /,
   'failure from trying to ->new an abstract class' );

class Derived {
   inherit Base;

   method m1 { return "concrete"; }
}

pass( 'Able to derive from abstract class Base by providing m1' );

{
   my $obj = Derived->new( f => "field-value" );
   ok( $obj, 'Able to construct an instance of Derived class' );

   is( $obj->m1, "concrete", 'Derived->m1' );
   is( $obj->m2, "field-value", 'Derived->m2' );
}

ok( !eval <<'EOPERL',
   class Base2 {
      inherit Base;
   }
EOPERL
   'derived concrete class without required method fails' );
like( $@, qr/^Class Base2 does not provide a required method named 'm1' at /,
   'message from failure to derive concrete class' );

class Base3 :abstract {
   inherit Base;
}

pass( 'Able to derive an abstract class from another without implementing missing methods' );

class Derived3 {
   inherit Base3;

   method m1 { return "non-abstract"; }
}

{
   my $obj = Derived3->new( f => "field-value" );
   ok( $obj, 'Able to construct an instance of Derived3 class' );

   is( $obj->m1, "non-abstract", 'Derived3->m1' );
}

done_testing;

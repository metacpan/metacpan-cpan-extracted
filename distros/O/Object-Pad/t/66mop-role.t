#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad ':experimental(mop)';

role Example {
   no warnings 'deprecated';

   method a_method;
   requires b_method;
}

my $meta = Object::Pad::MOP::Class->for_class( "Example" );

is( $meta->name, "Example", '$meta->name' );
ok(  $meta->is_role, '$meta->is_role true' );
ok( !$meta->is_class, '$meta->is_class false' );

is_deeply( [ $meta->required_method_names ], [qw( a_method b_method )],
   '$meta->required_method_names' );

class Implementor :does(Example) {
   method a_method {}
   method b_method {}
}

is_deeply( [ Object::Pad::MOP::Class->for_class( "Implementor" )->direct_roles ],
   [ $meta ],
   '$meta->direct_roles on implementing class' );

is_deeply( [ Object::Pad::MOP::Class->for_class( "Implementor" )->all_roles ],
   [ $meta ],
   '$meta->all_roles on implementing class' );

class Inheritor :isa(Implementor) {}

# Roles via subclass
{
   is_deeply( [ Object::Pad::MOP::Class->for_class( "Inheritor" )->direct_roles ],
      [],
      '$meta->direct_roles on inheriting class' );

   is_deeply( [ Object::Pad::MOP::Class->for_class( "Inheritor" )->all_roles ],
      [ $meta ],
      '$meta->all_roles on inheriting class' );
}

done_testing;

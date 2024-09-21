#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

class Example { }

my $meta = Object::Pad::MOP::Class->for_class( "Example" );

is( $meta->name, "Example", '$meta->name' );
ok(  $meta->is_class, '$meta->is_class true' );
ok( !$meta->is_role, '$meta->is_role false' );

is( [ $meta->superclasses ], [], '$meta->superclasses' );

is( [ $meta->direct_roles ], [], '$meta->direct_roles' );
is( [ $meta->all_roles    ], [], '$meta->all_roles' );

class Example2 { inherit Example; }

is( [ Object::Pad::MOP::Class->for_class( "Example2" )->superclasses ],
   [ $meta ],
   '$meta->superclasses on subclass' );

is( Object::Pad::MOP::Class->try_for_class( "main" ), undef,
   '->try_for_class does not throw' );

package NotObjectPad {
   use base qw( Example );
}

is( Object::Pad::MOP::Class->try_for_class( "NotObjectPad" ), undef,
   '->try_for_class not confused by non-OP subclasses' );

done_testing;

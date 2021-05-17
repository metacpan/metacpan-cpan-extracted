#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role Example { }

my $meta = Object::Pad::MOP::Class->for_class( "Example" );

is( $meta->name, "Example", '$meta->name' );
ok(  $meta->is_role, '$meta->is_role true' );
ok( !$meta->is_class, '$meta->is_class false' );

class Implementor implements Example {}

is_deeply( [ Object::Pad::MOP::Class->for_class( "Implementor" )->roles ],
   [ $meta ],
   '$meta->roles on implementing class' );

done_testing;

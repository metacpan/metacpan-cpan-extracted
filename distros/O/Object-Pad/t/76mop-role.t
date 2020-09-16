#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role Example { }

is( Example->META->name, "Example", 'META->name' );
ok(  Example->META->is_role, 'META->is_role true' );
ok( !Example->META->is_class, 'META->is_class false' );

class Implementor implements Example {}

is_deeply( [ Implementor->META->roles ], [ Example->META ],
   'META->roles on implementing class' );

done_testing;

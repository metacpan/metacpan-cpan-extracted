#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Example { }

is( Example->META->name, "Example", 'META->name' );
ok(  Example->META->is_class, 'META->is_class true' );
ok( !Example->META->is_role, 'META->is_role false' );

is_deeply( [ Example->META->superclasses ], [], 'META->superclasses' );

is_deeply( [ Example->META->roles ], [], 'META->roles' );

class Example2 extends Example {}

is_deeply( [ Example2->META->superclasses ], [ Example->META ],
   'META->superclasses on subclass' );

done_testing;

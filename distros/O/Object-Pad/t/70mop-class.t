#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Example { }

is( Example->META->name, "Example", 'META->name' );

is_deeply( [ Example->META->superclasses ], [], 'META->superclasses' );

class Example2 extends Example {}

is_deeply( [ Example2->META->superclasses ], [ Example->META ],
   'META->superclasses on subclass' );

done_testing;

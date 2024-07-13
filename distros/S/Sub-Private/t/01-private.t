#!perl -T

use strict;
use lib 't/';

use Test::Most tests => 5;
use Test::NoWarnings;
use Foo;

ok( Foo->can('foo'),     "Method foo not private" );
ok( !Foo->can('bar'),     "Method bar is private" );
ok( Foo->can('baz'),     "Method baz not private" );

is( Foo->baz(), 44,  "Method baz works" );




use strict;
use Test::More;

BEGIN { use_ok 'Object::Method' }

package Foo;
use Object::Method ();

package main;
my $o = bless {}, "Foo";
ok(! $o->can('method') );

done_testing;



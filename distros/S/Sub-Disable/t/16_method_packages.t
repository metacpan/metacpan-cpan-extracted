use Test::More;
my $test = 1;

package Foo;
use Sub::Disable 'foo', 'bar';

sub foo {$test = 2}
sub bar {$test = 3}

package Bar;
use Sub::Disable method => ['bar'];

sub foo {$test = 4}
sub bar {$test = 5}

package main;

Foo->foo;
is $test, 1;

Foo::bar();
is $test, 1;

Bar->foo;
is $test, 4;

Bar->bar;
is $test, 4;

Bar::bar();
is $test, 5;

Foo->bar;
is $test, 5;

done_testing;


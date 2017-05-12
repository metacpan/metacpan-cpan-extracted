#!perl

use Test::More tests => 2;

use t::FooBar;

is(t::FooBar::foo(123,'abc') => '123abc');
is(t::FooBar->bar(123,'abc') => '123abc');

done_testing;

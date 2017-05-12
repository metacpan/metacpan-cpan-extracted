#!perl -w
use strict;
use Test::More;
{
    package Foo;
    sub new { bless {}, shift }
}
{
    package Bar;
    sub new { bless {}, shift }
}

package Baz;
use Mouse;
use MouseX::Foreign;
eval { extends qw(Foo Bar) };
::like $@, qr/Multiple inheritance from foreign classes /;

package XFoo;
use Mouse;
use MouseX::Foreign qw(Foo);

package XBar;
use Mouse;
use MouseX::Foreign qw(Bar);

package Qux;
use Mouse;
use MouseX::Foreign;
eval { extends qw(XFoo XBar) };
::like $@, qr/Multiple inheritance from foreign classes /;

package main;
done_testing;

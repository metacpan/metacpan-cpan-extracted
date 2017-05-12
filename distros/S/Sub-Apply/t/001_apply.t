package Foo;
use strict;
use warnings;

my $n = 0;

sub called {
    return $n;
}

sub sum {
    $n++;
    my ( $x, $y ) = @_;
    return $x + $y;
}

package main;
use strict;
use warnings;
use Test::More tests => 4;
use Sub::Apply qw(apply);

sub sum { Foo::sum(@_); }

is apply( 'sum',      1, 2 ), 3, 'main::sum ok';
is apply( 'Foo::sum', 2, 3 ), 5, 'Foo::sum ok';
is Foo::called, 2, 'Foo::sum called 2';
{
    local $@;
    eval { apply( 'sprintf', 'hello' ) };
    ok $@, 'cannot called CORE function';
}

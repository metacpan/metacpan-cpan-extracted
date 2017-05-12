#!perl -w
use strict;
use Test::More;

use Sub::Spy qw/spy inspect/;

subtest("methods with single return value", sub {
    my $subref = sub { return shift; };
    my $spy = spy($subref);

    my $res = $spy->(1);
    is ( inspect($spy)->return_values->[0], 1, "return value 1 recorded" );
    is ( inspect($spy)->return_values->[0], inspect($spy)->get_return_value(0), "return value 1 recorded" );
});

subtest("methods with multiple return values", sub {
    my $subref = sub { return @_; };
    my $spy = spy($subref);

    my ( $one, $two, $three ) = $spy->(1, "foo", +{});
    is ( inspect($spy)->return_values->[0]->[0], 1, "return value 1 recorded" );
    is ( inspect($spy)->return_values->[0]->[1], "foo", "return value 1 recorded" );

    is ( inspect($spy)->return_values->[0]->[0], inspect($spy)->get_return_value(0)->[0], "return value 1 recorded" );
    is ( inspect($spy)->return_values->[0]->[1], inspect($spy)->get_return_value(0)->[1], "return value 1 recorded" );

    my ( $four, $five, $six ) = $spy->(2, "bar", +{});
    is ( inspect($spy)->get_return_value(1)->[0], 2, "return value 2 recorded" );
    is ( inspect($spy)->get_return_value(1)->[1], "bar", "return value 2 recorded" );
});

done_testing;

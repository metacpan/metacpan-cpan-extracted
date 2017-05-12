#!perl -w
use strict;
use Test::More;
use Test::Exception;

use Sub::Spy qw/spy inspect/;


subtest("methods about args", sub {
    my $subref = sub { return shift; };
    my $spy = spy($subref);

    $spy->("foo", "bar");
    is ( scalar @{inspect($spy)->args}, 1, "args recorded" );
    is ( inspect($spy)->args->[0]->[0], "foo", "args recorded" );

    $spy->("bar", "foobar");

    is ( inspect($spy)->get_args(0)->[0], "foo", "get_args recorded" );
    is ( inspect($spy)->get_args(0)->[1], "bar", "get_args recorded" );

    is ( inspect($spy)->get_args(1)->[0], "bar", "get_args recorded" );
    is ( inspect($spy)->get_args(1)->[1], "foobar", "get_args recorded" );

    dies_ok(sub {
        inspect($spy)->get_args(2)->[1];
    }, "dies if try to get not-yet-called call.");
});

done_testing;

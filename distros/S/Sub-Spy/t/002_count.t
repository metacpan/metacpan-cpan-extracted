#!perl -w
use strict;
use Test::More;

use Sub::Spy qw/spy inspect/;

subtest("basic methods about count", sub {
    my $subref = sub { return shift; };
    my $spy = spy($subref);

    $spy->();
    is ( inspect($spy)->call_count, 1, "spy call count = 1" );
    ok ( inspect($spy)->called, "spy has called!" );
    ok ( inspect($spy)->called_times(1), "spy has called once" );

    $spy->();
    is ( inspect($spy)->call_count, 2, "spy call count = 1" );
    ok ( inspect($spy)->called_times(2), "spy has called twice" );
});

subtest("methods about count", sub {
    my $subref = sub { return shift; };
    my $spy = spy($subref);

    $spy->();
    ok ( inspect($spy)->called_once, "spy called once" );
    ok ( ! inspect($spy)->called_twice, "spy called once" );

    $spy->();
    ok ( ! inspect($spy)->called_once, "spy called once" );
    ok ( inspect($spy)->called_twice, "spy called twice" );
    ok ( ! inspect($spy)->called_thrice, "spy called once" );

    $spy->();
    ok ( inspect($spy)->called_thrice, "spy called thrice" );
});

done_testing;

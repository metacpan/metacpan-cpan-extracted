#!perl -w
use strict;
use Test::More;
use Test::Exception;

use Sub::Spy qw/spy inspect/;


subtest("methods about exception", sub {
    my $subref = sub { die shift; };
    my $spy = spy($subref);

    $spy->("%%die%%");
    ok ( inspect($spy)->threw, "subref throws exception" );
    like ( inspect($spy)->exceptions->[0], qr/%%die%%/, "stores first exception" );
    like ( inspect($spy)->get_exception(0), qr/%%die%%/, "stores first exception" );

    $spy->("%%hoge%%");
    like ( inspect($spy)->get_exception(1), qr/%%hoge%%/, "stores second exception" );

    dies_ok(sub {
        inspect($spy)->get_exception(2);
    }, "dies if try to get not-yet-called call");
});

done_testing;

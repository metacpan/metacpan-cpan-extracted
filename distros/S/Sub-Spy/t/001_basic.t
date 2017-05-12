#!perl -w
use strict;
use Test::More;
use Test::Exception;

use Sub::Spy qw/spy inspect/;

subtest("new with subref that returns single value", sub {
    my $subref = sub { return shift; };
    my $spy = spy($subref);

    is ( $spy->(10), 10, "spy is callable and executes wrapped subref" );
    is ( $spy->(20), $subref->(20), "results of subref call and spy call just matches" );

    ok ( ref $spy eq "CODE" );
});

subtest("new with subref that returns multiple values", sub {
    my $subref = sub { return (1, 2, 3); };
    my $spy = spy($subref);

    my ( $one, $two, $three ) = $spy->();
    is ( $one, 1 );
    is ( $two, 2 );
    is ( $three, 3 );

    is ( $spy->(), 3, "return array length if called with scalar context" );
});

subtest("inspect", sub {
    my $subref1 = sub { return $_[0]; };
    my $spy1 = spy($subref1);

    my $subref2 = sub { return $_[0] * 2; };
    my $spy2 = spy($subref2);

    $spy1->(1);
    $spy2->(1);

    is ( inspect($spy1)->get_call(0)->return_value, 1 );
    is ( inspect($spy2)->get_call(0)->return_value, 2 );

    my $res = inspect($spy1);
    $spy1->(1);
    is ( $res->get_call(1)->return_value, 1 );

    dies_ok(sub {
        inspect(sub {});
    }, "dies if passwd not-spy-subref");
});

subtest("get_call", sub {
    my $subref = sub { return shift->(); };

    my $spy = spy($subref);

    $spy->(sub { return 1 });
    is ( inspect($spy)->get_call(0)->return_value, 1, "first call result is 1" );
    is ( inspect($spy)->get_call(0)->exception, undef, "first call did not throw exception" );
    is ( ref inspect($spy)->get_call(0)->args->[0], "CODE", "first call arg is subref" );

    $spy->(sub { die '%%die%%' });
    like ( inspect($spy)->get_call(1)->exception, qr/%%die%%/, "second call exception is ..." );
    is ( inspect($spy)->get_call(1)->return_value, undef, "second call did not return value" );
});

done_testing;

#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;
use Mock::Quick;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Class';
    use_ok( $CLASS );

    package Foo;

    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }

    1;
}

tests object => sub {
    my ($one, $control) = qobjc( foo => 'bar', baz => qmeth { 'baz' });
    $one->foo for 1 .. 4;
    $one->baz for 1 .. 10;

    is_deeply( $control->metrics, { foo => 4, baz => 10 }, "Kept metrics" );

    $control->clear( 'foo' );
    is_deeply( $control->metrics, { baz => 10 }, "Call count clears with method" );

    $one->baz( qclear() );
    is_deeply( $control->metrics, {}, "Call count clears with method" );

    $control->set_methods( foo => sub { 'foo' });
    $one->foo();
    is_deeply( $control->metrics, { foo => 1 }, "Kept metrics" );


    my @args;
    ($one, $control) = qobjc( foo => 'bar', baz => qmeth { @args = @_ });
    $one->baz( 'a', 'b' );

    is_deeply(
        [ @args ],
        [ $one, 'a', 'b' ],
        "Got Arguments"
    );
};

tests class => sub {
    my $class = qclass( -with_new => 1, foo => sub { 'bar' });
    my $one = $class->new();
    $one->foo() for 1 .. 4;

    $class->override( bar => 'baz' );
    $one->bar() for 1 .. 6;

    is_deeply( $class->metrics, { new => 1, foo => 4, bar => 6 }, "metrics" );

    $class->restore( 'foo' );
    is_deeply( $class->metrics, { new => 1, bar => 6 }, "metrics with restored method" );
};

run_tests;
done_testing;

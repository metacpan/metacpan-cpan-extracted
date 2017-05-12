#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;

our @INTERCEPT;
BEGIN {
    require_ok( 'Mock::Quick' );
    Mock::Quick->import( '-all', '-intercept' => sub {
        push @INTERCEPT => @_;
    });

    package Foo;
}

tests intercept => sub {
    qtakeover 'Foo' => (
        bar => sub { 'bar' },
    );

    ok( !Foo->can('bar'), "Mock has not happened yet" );

    is( @INTERCEPT, 1, "Intercepted the mock" );
    my $control = pop( @INTERCEPT )->();

    ok( Foo->can('bar'), "Mock happened" );
    isa_ok( $control, 'Mock::Quick::Class' );
    $control = undef;

    ok( !Foo->can('bar'), "Mock has been removed" );
};

run_tests;
done_testing;

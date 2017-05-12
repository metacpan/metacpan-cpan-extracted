#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moo;
    with 'MooseX::Role::Loggable';
}

{
    package Bar;
    use Moo;
    with 'MooseX::Role::Loggable';
}

{
    my $foo = Foo->new;
    isa_ok( $foo, 'Foo' );
    isa_ok( $foo->logger, 'Log::Dispatchouli' );
    cmp_ok( $foo->debug, '==', 0, 'debug is off in Foo' );
    cmp_ok(
        $foo->debug, '==', $foo->logger->{'debug'},
        'debug flag matches in Foo',
    );

    my $bar = Bar->new( debug => 1 );
    isa_ok( $bar, 'Bar' );
    isa_ok( $bar->logger, 'Log::Dispatchouli' );
    cmp_ok( $bar->debug, '==', 1, 'debug is on in Bar' );
    cmp_ok(
        $bar->debug, '==', $bar->logger->{'debug'},
        'debug flag matches in Bar',
    );
}

{
    my $foo = Foo->new( debug => 1 );
    isa_ok( $foo, 'Foo' );
    isa_ok( $foo->logger, 'Log::Dispatchouli' );
    cmp_ok( $foo->debug, '==', 1, 'debug is on in Foo' );
    cmp_ok(
        $foo->debug, '==', $foo->logger->{'debug'},
        'debug flag matches in Foo',
    );

    my $bar = Bar->new( logger => $foo->logger );
    isa_ok( $bar, 'Bar' );
    isa_ok( $bar->logger, 'Log::Dispatchouli' );
    cmp_ok( $bar->debug, '==', 1, 'debug is on in Bar' );
    cmp_ok(
        $bar->debug, '==', $bar->logger->{'debug'},
        'debug flag propagated from Foo to Bar successfully',
    );
    cmp_ok(
        $bar->logger->{'debug'}, '==', 1,
        'Logger has debug flag of Bar',
    );
}

{
    my $foo = Foo->new();
    isa_ok( $foo, 'Foo' );
    isa_ok( $foo->logger, 'Log::Dispatchouli' );
    cmp_ok( $foo->debug, '==', 0, 'debug is off in Foo' );
    cmp_ok(
        $foo->debug, '==', $foo->logger->{'debug'},
        'debug flag matches in Foo',
    );

    my $bar = Bar->new( logger => $foo->logger, debug => 1 );
    isa_ok( $bar, 'Bar' );
    isa_ok( $bar->logger, 'Log::Dispatchouli' );
    cmp_ok( $bar->debug, '==', 1, 'debug is on in Bar' );
    cmp_ok(
        $bar->debug, '==', $bar->logger->{'debug'},
        'Bar overridden debug flag in logger successfully',
    );
    cmp_ok(
        $bar->logger->{'debug'}, '==', 1,
        'Logger has debug flag of Bar',
    );
}

done_testing;


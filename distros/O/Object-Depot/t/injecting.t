#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Object::Depot;

{ package Test::injection; use Moo }

subtest basic => sub{
    my $depot = Object::Depot->new(
        class => 'Test::injection',
    );

    my $regular = $depot->fetch('foo');
    my $custom = $depot->create('foo');

    is( $depot->injection('foo'), undef, 'not injected' );
    is( $depot->fetch('foo'), $regular, 'fetch returned regular object' );

    $depot->inject( foo => $custom );
    isnt( $depot->injection('foo'), undef, 'is injected' );
    is( $depot->fetch('foo'), $custom, 'fetch returned custom object' );

    $depot->clear_injection('foo');
    is( $depot->injection('foo'), undef, 'not injected' );
    is( $depot->fetch('foo'), $regular, 'fetch returned regular object' );
};

subtest default_key => sub{
    my $depot = Object::Depot->new(
        class => 'Test::injection',
        default_key => 'foo',
    );

    my $regular = $depot->fetch();
    my $custom = $depot->create();

    is( $depot->injection(), undef, 'not injected' );
    is( $depot->fetch(), $regular, 'fetch returned regular object' );

    $depot->inject( foo => $custom );
    isnt( $depot->injection(), undef, 'is injected' );
    is( $depot->fetch(), $custom, 'fetch returned custom object' );

    $depot->clear_injection();
    is( $depot->injection(), undef, 'not injected' );
    is( $depot->fetch(), $regular, 'fetch returned regular object' );
};

subtest guard => sub{
    my $depot = Object::Depot->new(
        class => 'Test::injection',
    );

    my $regular = $depot->fetch('foo');
    my $custom = $depot->create('foo');

    is( $depot->injection('foo'), undef, 'not injected' );
    is( $depot->fetch('foo'), $regular, 'fetch returned regular object' );

    my $guard = $depot->inject_with_guard( foo => $custom );
    isnt( $depot->injection('foo'), undef, 'is injected' );
    is( $depot->fetch('foo'), $custom, 'fetch returned custom object' );

    $guard = undef;
    is( $depot->injection('foo'), undef, 'not injected' );
    is( $depot->fetch('foo'), $regular, 'fetch returned regular object' );
};

done_testing;

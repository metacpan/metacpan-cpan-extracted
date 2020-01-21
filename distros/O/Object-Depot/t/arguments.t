#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Object::Depot;

subtest default_key => sub{
    my $depot = Object::Depot->new(
        default_key => 'default',
    );
    $depot->add_key( 'default', {foo=>2} );

    is(
        $depot->arguments(),
        { foo=>2 },
        'got default arguments',
    );
};

subtest undeclared_key => sub{
    my $depot = Object::Depot->new();
    $depot->add_key( key2 => {foo=>'bar'} );

    is(
        $depot->arguments('key1'),
        {},
        'empty arguments',
    );

    is(
        $depot->arguments('key2'),
        {foo=>'bar'},
        'has arguments',
    );
};

subtest key_argument => sub{
    package Test::arguments::key_arguments;
        use Moo;
        has foo1 => (is=>'ro');
        has foo2 => (is=>'ro');
    package main;

    my $depot = Object::Depot->new(
        class => 'Test::arguments::key_arguments',
        key_argument => 'foo2',
    );

    $depot->add_key( bar2 => {foo1=>'bar1'} );

    my $object = $depot->fetch( 'bar2' );

    is( $object->foo1(), 'bar1', 'key argument was set' );
    is( $object->foo2(), 'bar2', 'key argument was set' );
};

subtest default_arguments => sub{
    package Test::arguments::default_arguments;
        use Moo;
        has foo1 => ( is=>'ro' );
        has foo2 => ( is=>'ro' );
        has foo3 => ( is=>'ro' );
    package main;

    my $depot = Object::Depot->new(
        class => 'Test::arguments::default_arguments',
        default_arguments => {
            foo1 => 'bar1',
            foo2 => 'bar2',
        },
    );

    $depot->add_key(
        'test',
        foo2 => 'BAZ2',
        foo3 => 'bar3',
    );

    my $object = $depot->fetch('test');

    is( $object->foo1(), 'bar1', 'default argument was set' );
    is( $object->foo2(), 'BAZ2', 'default argument was replaced' );
    is( $object->foo3(), 'bar3', 'other argument was set' );
};

done_testing;

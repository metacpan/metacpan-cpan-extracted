#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Object::Depot;

subtest basic => sub{
    my $depot = Object::Depot->new();

    like(
        dies{ $depot->_process_key_arg([]) },
        qr{No key was passed},
    );

    like(
        dies{ $depot->_process_key_arg([undef]) },
        qr{No key was passed},
    );

    is(
        $depot->_process_key_arg(['foo']),
        'foo',
    );

    my $object = bless {}, 'Foo';

    like(
        dies{ $depot->_process_key_arg([$object]) },
        qr{No key was passed},
    );

    is(
        $depot->_process_key_arg(['foo',$object]),
        'foo',
    );

    like(
        dies{ $depot->_process_key_arg([undef,$object]) },
        qr{No key was passed},
    );
};

subtest default_key => sub{
    my $depot = Object::Depot->new(
        default_key => 'bar',
    );

    is(
        $depot->_process_key_arg([]),
        'bar',
    );

    is(
        $depot->_process_key_arg([undef]),
        'bar',
    );

    is(
        $depot->_process_key_arg(['foo']),
        'foo',
    );

    my $object = bless {}, 'Foo';

    is(
        $depot->_process_key_arg([$object]),
        'bar',
    );

    is(
        $depot->_process_key_arg(['foo',$object]),
        'foo',
    );

    is(
        $depot->_process_key_arg([undef,$object]),
        'bar',
    );
};

done_testing;

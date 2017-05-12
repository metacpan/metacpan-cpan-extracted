#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 12;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo');
    is ($foo->mocked_state, 1, "obj 1 has proper mock state");

    is ($mock->mocked_state('One::foo'), 1, "mock has proper mock state on obj 1");

    my $bar = $mock->mock('One::bar');
    is ($bar->mocked_state, 1, "obj 2 has proper mock state");
    is ($bar->mocked_state, 1, "mock has proper mock state on obj 2");

    $foo->unmock;
    is ($foo->mocked_state, 0, "obj 1 has proper unmock state");
    is ($mock->mocked_state('One::foo'), 0, "mock has proper ummock state on obj 1");

    my $mock2 = Mock::Sub->new;

    eval { $mock2->mocked_state('One::foo'); };
    like (
        $@,
        qr/can't call mocked_state()/,
        "can't call mocked_state() on parent if a child hasn't been initialized and mocked"
    );

    $foo->remock;
    is ($foo->mocked_state, 1, "obj has proper mock state with 2 mocks");
    is ($foo->mocked_state, 1, "...and original mock obj still has state");

    eval { $mock->mocked_state; };
    like ($@, qr/calling mocked_state()/, "can't call mocked_state on a top-level obj");
}


#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    eval { $foo->_mock; };
    like ($@, qr/\Qthe _mock() method is not a public\E/, "mock() renamed to _mock() no longer callable");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    is ($foo->mocked_state, 1, "sub is mocked");

    $foo->unmock;

    is ($foo->mocked_state, 0, "sub is unmocked");

    $foo->remock;

    is ($foo->mocked_state, 1, "sub is re-mocked with remock()");

    eval { $foo->remock; };

    is ($@, '', "remock() can be called on an already mocked sub");

    $foo->remock(return_value => 55);

    is (One::foo(), 55, "remocking a mocked sub with a param works");
}

done_testing();


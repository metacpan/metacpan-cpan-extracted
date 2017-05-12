#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 19;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo', return_value => 'Mocked');
    my $ret = One::foo();
    is ($ret, 'Mocked', "One::foo is mocked");

    $foo->unmock;
    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unmocked with unmock()");

    $foo->remock(return_value => 'Mocked');
    $ret = One::foo();
    is ($foo->called_count, 1, "call count is proper in obj void context");
    is ($ret, 'Mocked', "One::foo is mocked after being unmocked");
    is ($ret, 'Mocked', "mock() with a child object in void is remocked");

    $foo->unmock;

    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unmocked again");
}
{
    $SIG{__WARN__} = sub {};
    my $mock = Mock::Sub->new;
    my $fake = $mock->mock('X::y', return_value => 'true');

    my $ret = X::y();
    is ($ret, 'true', "successfully mocked a non-existent sub");
    is ($fake->{orig}, undef, "fake mock doesn't keep sub history");

    $fake->unmock;
    eval { X::y(); };
    like ($@, qr/Undefined subroutine/,
          "unmock() unloads the symtab entry for the faked sub"
    );
}
{
    my $mock = Mock::Sub->new;

    my $pre_mock_ret = One::foo();
    is ($pre_mock_ret, 'foo', "pre_mock value is $pre_mock_ret");

    my $obj = $mock->mock('One::foo', return_value => 'mocked');

    my $post_mock_ret = One::foo();
    is ($post_mock_ret, 'mocked', "post_mock value is $post_mock_ret");

    $obj->DESTROY;

    my $post_destroy_ret = One::foo();
    is ($post_destroy_ret, 'foo', "post_destroy value is $post_destroy_ret");

}
{
    # test DESTROY()

    my $mock = Mock::Sub->new;

    my $ret = One::foo();
    is ($ret, 'foo', "pre_mock value is $ret");

    {
        my $foo = $mock->mock('One::foo', return_value => 'mocked');
        my $in_ret = One::foo();
        is ($in_ret, 'mocked', "mock value is $in_ret");
    }

    my $post_ret = One::foo();
    is ($post_ret, 'foo', "auto destroy/unmock works properly")
}
{
    # test DESTROY() no calls

    my $mock = Mock::Sub->new;

    my $ret = One::foo();
    is ($ret, 'foo', "pre_mock value is $ret");

    {
        my $foo = $mock->mock(
            'One::foo',
            return_value => 'mocked',
            );
    }

    my $post_ret = One::foo();
    is ($post_ret, 'foo', "DESTROY() is called if the mocked sub isn't called")
}

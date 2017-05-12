#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo');
    my $bar = $mock->mock('One::bar');
    my $baz = $mock->mock('One::baz');

    my @names;

    @names = $mock->mocked_subs;

    is (@names, 3, "return is correct");

    $foo->unmock;

    @names = $mock->mocked_subs;
    is (@names, 2, "after unmock, return is correct");
    my @ret1 =  grep /One::foo/, @names;
    is ($ret1[0], undef, "the unmocked sub isn't in the list of names");

    $foo->remock('One::foo');

    @names = $mock->mocked_subs;

    my @ret2 =  grep /One::foo/, @names;
    is (@names, 3, "after re-mock, return is correct");
    is ($ret2[0], 'One::foo', "the unmocked sub isn't in the list of names");
}

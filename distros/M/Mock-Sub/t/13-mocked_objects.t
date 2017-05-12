#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 11;

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

    my @objects = $mock->mocked_objects;

    is (@objects, 3, 'returns correct number of objects');

    $foo->unmock;

    is ($foo->mocked_state, 0, "unmocked sub");

    is ($mock->mocked_objects, 3, "after an unmock, return is still correct");

    $foo->remock;

    for my $obj (@objects){
        is ($obj->mocked_state, 1, "objects can call state");
        like ($obj->name, qr/(?:One::foo|One::bar|One::baz)/, "name is correct on all objects");
    }
}

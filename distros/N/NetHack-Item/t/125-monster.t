#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $statue = $pool->new_item("a statue of a snake");
is($statue->monster->name, 'snake');

TODO: eval {
    my $tin = $pool->new_item("a tin of snake meat");
    is($tin->monster->name, 'snake');
};

TODO: eval {
    my $egg = $pool->new_item("a snake egg");
    is($egg->monster->name, 'snake');
};

done_testing;

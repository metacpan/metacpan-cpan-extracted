#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;

# @ISA magic
{
    my $Foo = Package::Stash->new('ISAFoo');
    $Foo->add_symbol('&foo' => sub { });

    my $Bar = Package::Stash->new('ISABar');
    @{ $Bar->get_or_add_symbol('@ISA') } = ('ISAFoo');
    can_ok('ISABar', 'foo');

    my $Foo2 = Package::Stash->new('ISAFoo2');
    $Foo2->add_symbol('&foo2' => sub { });
    @{ $Bar->get_or_add_symbol('@ISA') } = ('ISAFoo2');
    can_ok('ISABar', 'foo2');
    ok(!Bar->can('foo'));
}

{
    my $main = Package::Stash->new('main');
    $main->add_symbol('$"', '-');
    my @foo = qw(a b c);
    is(eval q["@foo"], 'a-b-c');
}

SKIP: {
    skip "only need to test for magic in the xs version", 10
        unless $Package::Stash::IMPLEMENTATION eq 'XS';
    skip "magic stashes require perl 5.10+", 10
        unless $] >= 5.010;
    skip "magic stashes require Variable::Magic", 10
        unless eval { require Variable::Magic; 1 };

    my ($fetch, $store);
    my $wiz = Variable::Magic::wizard(
        fetch => sub { $fetch++ },
        store => sub { $store++ },
    );
    Variable::Magic::cast(\%MagicStashTest::, $wiz);

    my $stash = Package::Stash->new('MagicStashTest');

    $fetch = 0;
    $store = 0;
    $stash->get_symbol('@foo');
    is($fetch, 1, "get_symbol fetches (empty slot)");
    is($store, 0, "get_symbol stores (empty slot)");

    $fetch = 0;
    $store = 0;
    $stash->get_or_add_symbol('@bar');
    is($fetch, 0, "get_or_add_symbol fetches (empty slot)");
    is($store, 1, "get_or_add_symbol stores (empty slot)");

    $fetch = 0;
    $store = 0;
    $stash->add_symbol('@baz', ['baz']);
    is($fetch, 0, "add_symbol fetches");
    is($store, 1, "add_symbol stores");

    $fetch = 0;
    $store = 0;
    $stash->get_symbol('@baz');
    is($fetch, 1, "get_symbol fetches (populated slot)");
    is($store, 0, "get_symbol stores (populated slot)");

    $fetch = 0;
    $store = 0;
    $stash->get_or_add_symbol('@baz');
    is($fetch, 1, "get_or_add_symbol fetches (populated slot)");
    is($store, 0, "get_or_add_symbol stores (populated slot)");
}

done_testing;

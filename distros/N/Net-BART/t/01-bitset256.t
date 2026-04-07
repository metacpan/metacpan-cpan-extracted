#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Net::BART::BitSet256;

# Basic set/test/clear
{
    my $bs = Net::BART::BitSet256->new;
    ok(!$bs->test(0), 'bit 0 initially clear');
    $bs->set(0);
    ok($bs->test(0), 'bit 0 set');
    $bs->clear(0);
    ok(!$bs->test(0), 'bit 0 cleared');
}

# Test all 4 words
{
    my $bs = Net::BART::BitSet256->new;
    for my $bit (0, 63, 64, 127, 128, 191, 192, 255) {
        $bs->set($bit);
        ok($bs->test($bit), "bit $bit set correctly");
    }
}

# Rank
{
    my $bs = Net::BART::BitSet256->new;
    $bs->set(5);
    $bs->set(10);
    $bs->set(200);

    is($bs->rank(4), 0, 'rank(4) = 0');
    is($bs->rank(5), 1, 'rank(5) = 1');
    is($bs->rank(9), 1, 'rank(9) = 1');
    is($bs->rank(10), 2, 'rank(10) = 2');
    is($bs->rank(199), 2, 'rank(199) = 2');
    is($bs->rank(200), 3, 'rank(200) = 3');
    is($bs->rank(255), 3, 'rank(255) = 3');
}

# intersection_top
{
    my $a = Net::BART::BitSet256->new;
    my $b = Net::BART::BitSet256->new;

    $a->set(1); $a->set(3); $a->set(13);
    $b->set(1); $b->set(6); $b->set(13); $b->set(200);

    is($a->intersection_top($b), 13, 'intersection_top finds highest common bit');
}

# intersection_top empty
{
    my $a = Net::BART::BitSet256->new;
    my $b = Net::BART::BitSet256->new;
    $a->set(1);
    $b->set(2);
    is($a->intersection_top($b), -1, 'intersection_top returns -1 for disjoint sets');
}

# intersects
{
    my $a = Net::BART::BitSet256->new;
    my $b = Net::BART::BitSet256->new;
    ok(!$a->intersects($b), 'empty sets do not intersect');
    $a->set(42);
    ok(!$a->intersects($b), 'no intersection with empty');
    $b->set(42);
    ok($a->intersects($b), 'sets intersect at bit 42');
}

# is_empty
{
    my $bs = Net::BART::BitSet256->new;
    ok($bs->is_empty, 'new bitset is empty');
    $bs->set(100);
    ok(!$bs->is_empty, 'bitset not empty after set');
    $bs->clear(100);
    ok($bs->is_empty, 'bitset empty after clear');
}

# popcnt
{
    my $bs = Net::BART::BitSet256->new;
    is($bs->popcnt, 0, 'popcnt of empty = 0');
    $bs->set(1); $bs->set(100); $bs->set(255);
    is($bs->popcnt, 3, 'popcnt = 3');
}

# each_set_bit
{
    my $bs = Net::BART::BitSet256->new;
    $bs->set(3); $bs->set(64); $bs->set(200);
    my @bits;
    $bs->each_set_bit(sub { push @bits, $_[0] });
    is_deeply(\@bits, [3, 64, 200], 'each_set_bit iterates in order');
}

done_testing;

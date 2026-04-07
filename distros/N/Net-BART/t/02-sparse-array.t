#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Net::BART::SparseArray256;

# Basic insert/get
{
    my $sa = Net::BART::SparseArray256->new;
    ok($sa->is_empty, 'new array is empty');

    my $is_new = $sa->insert_at(10, 'hello');
    is($is_new, 1, 'insert returns 1 for new');
    is($sa->len, 1, 'length is 1');

    my ($val, $ok) = $sa->get(10);
    ok($ok, 'get returns ok');
    is($val, 'hello', 'get returns correct value');

    ($val, $ok) = $sa->get(11);
    ok(!$ok, 'get for missing index returns not ok');
}

# Update
{
    my $sa = Net::BART::SparseArray256->new;
    $sa->insert_at(5, 'a');
    my $is_new = $sa->insert_at(5, 'b');
    is($is_new, 0, 'insert returns 0 for update');
    my ($val, $ok) = $sa->get(5);
    is($val, 'b', 'value updated');
    is($sa->len, 1, 'length unchanged');
}

# Multiple inserts maintain order
{
    my $sa = Net::BART::SparseArray256->new;
    $sa->insert_at(100, 'c');
    $sa->insert_at(5, 'a');
    $sa->insert_at(50, 'b');

    is($sa->len, 3, 'length is 3');

    my ($v1) = $sa->get(5);
    my ($v2) = $sa->get(50);
    my ($v3) = $sa->get(100);
    is($v1, 'a', 'get(5)');
    is($v2, 'b', 'get(50)');
    is($v3, 'c', 'get(100)');
}

# Delete
{
    my $sa = Net::BART::SparseArray256->new;
    $sa->insert_at(10, 'x');
    $sa->insert_at(20, 'y');
    $sa->insert_at(30, 'z');

    my ($old, $ok) = $sa->delete_at(20);
    ok($ok, 'delete returns ok');
    is($old, 'y', 'delete returns old value');
    is($sa->len, 2, 'length decreased');

    my ($val);
    ($val, $ok) = $sa->get(20);
    ok(!$ok, 'deleted index no longer present');

    ($val) = $sa->get(10);
    is($val, 'x', 'other values intact');
    ($val) = $sa->get(30);
    is($val, 'z', 'other values intact');
}

# Delete non-existent
{
    my $sa = Net::BART::SparseArray256->new;
    my ($old, $ok) = $sa->delete_at(5);
    ok(!$ok, 'delete non-existent returns not ok');
}

# each_pair
{
    my $sa = Net::BART::SparseArray256->new;
    $sa->insert_at(200, 'c');
    $sa->insert_at(1, 'a');
    $sa->insert_at(128, 'b');

    my @pairs;
    $sa->each_pair(sub { push @pairs, [$_[0], $_[1]] });
    is_deeply(\@pairs, [[1, 'a'], [128, 'b'], [200, 'c']], 'each_pair in index order');
}

done_testing;

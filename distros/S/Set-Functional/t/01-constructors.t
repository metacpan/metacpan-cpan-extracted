#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;
use Set::Functional qw{:all};

sub order { sort { $a <=> $b } @_ }
sub order_by_id { sort { $a->{id} <=> $b->{id} } @_ }

my @arr_num1 = (1 .. 10);
my @arr_num2 = (6 .. 15);

my @arr_id1 = map { +{id => $_} } @arr_num1;
my @arr_id2 = map { +{id => $_} } @arr_num2;

is_deeply [setify], [], 'setify returns the empty set with no input';
is_deeply [setify 10], [10], 'setify returns the only element with one input';
is_deeply
	[order setify @arr_num1, @arr_num2],
	[1 .. 15],
	'setify returns deduplicated elements with many inputs';
is_deeply
	[order setify map {$_} @arr_num1, @arr_num2],
	[1 .. 15],
	'setify works with internal iterators';

is_deeply [setify_by {$_[0]{id}}], [], 'setify_by returns the empty set with no input';
is_deeply [setify_by {$_[0]{id}} +{id => 10}], [{id => 10}], 'setify_by returns the only element with one input';
is_deeply
	[order_by_id setify_by {$_[0]{id}} @arr_id1, @arr_id2],
	[map {+{id => $_}} 1 .. 15],
	'setify_by returns deduplicated elements with many inputs';
is_deeply
	[order_by_id setify_by {$_[0]{id}} map {$_} @arr_id1, @arr_id2],
	[map {+{id => $_}} 1 .. 15],
	'setify_by works with internal iterators';


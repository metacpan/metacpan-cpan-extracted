#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 60;
use Set::Functional qw{:all};

sub order { sort { $a <=> $b } @_ }
sub order_by_id { sort { $a->{id} <=> $b->{id} } @_ }

my @arr_num1 = (1 .. 10);
my @arr_num2 = (6 .. 15);
my @arr_num3 = map { $_ * 2 } (1 .. 10);
my @arr_nums = (\@arr_num1, \@arr_num2, \@arr_num3);

my @arr_id1 = map { +{id => $_} } @arr_num1;
my @arr_id2 = map { +{id => $_} } @arr_num2;
my @arr_id3 = map { +{id => $_} } @arr_num3;
my @arr_ids = (\@arr_id1, \@arr_id2, \@arr_id3);

#Difference
is_deeply [difference], [], 'difference returns the empty set with no sets';
is_deeply [order difference \@arr_num1], \@arr_num1, 'difference returns the same elements with one set';
is_deeply [order difference \@arr_num1, []], \@arr_num1, 'difference with the empty set returns the first set';
is_deeply
	[order difference @arr_nums],
	[1, 3, 5],
	'difference returns only the elements in the first set';
is_deeply
	[order difference map {$_} @arr_nums],
	[1, 3, 5],
	'difference works with internal iterators';

is_deeply [difference_by {$_[0]{id}}], [], 'difference_by returns the empty set with no sets';
is_deeply [order_by_id difference_by {$_[0]{id}} \@arr_id1], \@arr_id1, 'difference_by returns the same elements with one set';
is_deeply [order_by_id difference_by {$_[0]{id}} \@arr_id1, []], \@arr_id1, 'difference_by with the empty set returns the first set';
is_deeply
	[order_by_id difference_by {$_[0]{id}} @arr_ids],
	[map {+{id => $_}} 1, 3, 5],
	'difference_by returns only the elements in the first set';
is_deeply
	[order_by_id difference_by {$_[0]{id}} map {$_} @arr_ids],
	[map {+{id => $_}} 1, 3, 5],
	'difference_by works with internal iterators';

#Disjoint
is_deeply [disjoint], [], 'disjoint returns no sets with no sets';
is_deeply [order disjoint \@arr_num1], [\@arr_num1], 'disjoint returns the same elements with one set';
is_deeply [map {[order @$_]} disjoint \@arr_num1, []], [\@arr_num1, []], 'disjoint with the empty set returns the first set and the empty set';
is_deeply
	[map {[order @$_]} disjoint @arr_nums],
	[[1,3,5],[11,13,15],[16,18,20]],
	'disjoint returns associated sets with the elements that only occur once in all sets';
is_deeply
	[map {[order @$_]} disjoint map {$_} @arr_nums],
	[[1,3,5],[11,13,15],[16,18,20]],
	'disjoint works with internal iterators';

is_deeply [disjoint_by {$_[0]{id}}], [], 'disjoint_by returns no sets with no sets';
is_deeply [order_by_id disjoint_by {$_[0]{id}} \@arr_id1], [\@arr_id1], 'disjoint_by returns the same elements with one set';
is_deeply [map {[order_by_id @$_]} disjoint_by {$_[0]{id}} \@arr_id1, []], [\@arr_id1, []], 'disjoint_by with the empty set returns the first set and the empty set';
is_deeply
	[map {[order_by_id @$_]} disjoint_by {$_[0]{id}} @arr_ids],
	[[map {+{id => $_}} 1,3,5], [map {+{id => $_}} 11,13,15], [map {+{id => $_}} 16,18,20]],
	'disjoint_by returns associated sets with the elements that only occur once in all sets';
is_deeply
	[map {[order_by_id @$_]} disjoint_by {$_[0]{id}} map {$_} @arr_ids],
	[[map {+{id => $_}} 1,3,5], [map {+{id => $_}} 11,13,15], [map {+{id => $_}} 16,18,20]],
	'disjoint_by works with internal iterators';

#Distinct
is_deeply [distinct], [], 'distinct returns the empty set with no sets';
is_deeply [order distinct \@arr_num1], \@arr_num1, 'distinct returns the same elements with one set';
is_deeply [order distinct \@arr_num1, []], \@arr_num1, 'distinct with the empty set returns all the elements from the first set';
is_deeply
	[order distinct @arr_nums],
	[1,3,5,11,13,15,16,18,20],
	'distinct returns the elements that only occur once in all sets';
is_deeply
	[order distinct map {$_} @arr_nums],
	[1,3,5,11,13,15,16,18,20],
	'distinct works with internal iterators';

is_deeply [distinct_by {$_[0]{id}}], [], 'distinct_by returns the empty set with no sets';
is_deeply [order_by_id distinct_by {$_[0]{id}} \@arr_id1], \@arr_id1, 'distinct_by returns the same elements with one set';
is_deeply [order_by_id distinct_by {$_[0]{id}} \@arr_id1, []], \@arr_id1, 'distinct_by with the empty set returns all the elements from the first set';
is_deeply
	[order_by_id distinct_by {$_[0]{id}} @arr_ids],
	[map {+{id => $_}} 1,3,5,11,13,15,16,18,20],
	'distinct_by returns the elements that only occur once in all sets';
is_deeply
	[order_by_id distinct_by {$_[0]{id}} map {$_} @arr_ids],
	[map {+{id => $_}} 1,3,5,11,13,15,16,18,20],
	'distinct_by works with internal iterators';

#Intersection
is_deeply [intersection], [], 'intersection returns the empty set with no sets';
is_deeply [order intersection \@arr_num1], \@arr_num1, 'intersection returns the same elements with one set';
is_deeply [order intersection \@arr_num1, []], [], 'intersection with the empty set returns the empty set';
is_deeply
	[order intersection @arr_nums],
	[6,8,10],
	'intersection returns only the elements that occur in all sets';
is_deeply
	[order intersection map {$_} @arr_nums],
	[6,8,10],
	'intersection works with internal iterators';

is_deeply [intersection_by {$_[0]{id}}], [], 'intersection_by returns the empty set with no sets';
is_deeply [order_by_id intersection_by {$_[0]{id}} \@arr_id1], \@arr_id1, 'intersection_by returns the same elements with one set';
is_deeply [order_by_id intersection_by {$_[0]{id}} \@arr_id1, []], [], 'intersection_by with the empty set returns the empty set';
is_deeply
	[order_by_id intersection_by {$_[0]{id}} @arr_ids],
	[map {+{id => $_}} 6,8,10],
	'intersection_by returns only the elements that occur in all sets';
is_deeply
	[order_by_id intersection_by {$_[0]{id}} map {$_} @arr_ids],
	[map {+{id => $_}} 6,8,10],
	'intersection_by works with internal iterators';

#Symmetric Difference
is_deeply [symmetric_difference], [], 'symmetric_difference returns the empty set with no sets';
is_deeply [order symmetric_difference \@arr_num1], \@arr_num1, 'symmetric_difference returns the same elements with one set';
is_deeply [order symmetric_difference \@arr_num1, []], \@arr_num1, 'symmetric_difference with the empty set returns the first set';
is_deeply
	[order symmetric_difference @arr_nums],
	[1,3,5,6,8,10,11,13,15,16,18,20],
	'symmetric_difference returns only the elements that occur an odd number fo times in all sets';
is_deeply
	[order symmetric_difference map {$_} @arr_nums],
	[1,3,5,6,8,10,11,13,15,16,18,20],
	'symmetric_difference works with internal iterators';

is_deeply [symmetric_difference_by {$_[0]{id}}], [], 'symmetric_difference_by returns the empty set with no sets';
is_deeply [order_by_id symmetric_difference_by {$_[0]{id}} \@arr_id1], \@arr_id1, 'symmetric_difference_by returns the same elements with one set';
is_deeply [order_by_id symmetric_difference_by {$_[0]{id}} \@arr_id1, []], \@arr_id1, 'symmetric_difference_by with the empty set returns the first set';
is_deeply
	[order_by_id symmetric_difference_by {$_[0]{id}} @arr_ids],
	[map {+{id => $_}} 1,3,5,6,8,10,11,13,15,16,18,20],
	'symmetric_difference_by returns only the elements that occur an odd number of times in all sets';
is_deeply
	[order_by_id symmetric_difference_by {$_[0]{id}} map {$_} @arr_ids],
	[map {+{id => $_}} 1,3,5,6,8,10,11,13,15,16,18,20],
	'symmetric_difference_by works with internal iterators';

#Union
is_deeply [union], [], 'union returns the empty set with no sets';
is_deeply [order union \@arr_num1], \@arr_num1, 'union returns the same elements with one set';
is_deeply [order union \@arr_num1, []], \@arr_num1, 'union with the empty set returns the first set';
is_deeply
	[order union @arr_nums],
	[1 .. 16, 18, 20],
	'union returns all the elements that occur in any set';
is_deeply
	[order union map {$_} @arr_nums],
	[1 .. 16, 18, 20],
	'union works with internal iterators';

is_deeply [union_by {$_[0]{id}}], [], 'union_by returns the empty set with no sets';
is_deeply [order_by_id union_by {$_[0]{id}} \@arr_id1], \@arr_id1, 'union_by returns the same elements with one set';
is_deeply [order_by_id union_by {$_[0]{id}} \@arr_id1, []], \@arr_id1, 'union_by with the empty set returns the first set';
is_deeply
	[order_by_id union_by {$_[0]{id}} @arr_ids],
	[map {+{id => $_}} 1 .. 16, 18, 20],
	'union_by returns all the elements that occur in any set';
is_deeply
	[order_by_id union_by {$_[0]{id}} map {$_} @arr_ids],
	[map {+{id => $_}} 1 .. 16, 18, 20],
	'union_by works with internal iterators';

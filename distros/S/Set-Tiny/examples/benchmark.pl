#!/usr/bin/perl
use strict;
use lib 'lib';

# non-representative benchmark of different Set:: modules

use Benchmark qw( cmpthese );

use Set::Tiny;
use Set::Scalar;
use Set::Object;

my @a =  1 .. 100;
my @b = 51 .. 150;

my $s_t1 = Set::Tiny->new(@a);
my $s_t2 = Set::Tiny->new(@b);

my $s_s1 = Set::Scalar->new(@a);
my $s_s2 = Set::Scalar->new(@b);

my $s_o1 = Set::Object->new(@a);
my $s_o2 = Set::Object->new(@b);

my %tests = (
    new => {
        t => sub { Set::Tiny->new(@a) },
        s => sub { Set::Scalar->new(@a) },
        o => sub { Set::Object->new(@a) },
    },
    # Set::Object doesn't have a clone() method
    #clone => {
    #    t => sub { $s_t1->clone },
    #    s => sub { $s_s1->clone },
    #    o => sub { },
    #},
    insert => {
        t => sub { Set::Tiny->new->insert(@a) },
        s => sub { Set::Scalar->new->insert(@a) },
        o => sub { Set::Object->new->insert(@a) },
    },
    delete => {
        t => sub { Set::Tiny->new(@a)->delete(@b) },
        s => sub { Set::Scalar->new(@a)->delete(@b) },
        o => sub { Set::Object->new(@a)->delete(@b) },
    },
    invert => {
        t => sub { Set::Tiny->new(@a)->invert(@b) },
        s => sub { Set::Scalar->new(@a)->invert(@b) },
        o => sub { Set::Object->new(@a)->invert(@b) },
    },
    is_equal => {
        t => sub { $s_t1->is_equal($s_t2) },
        s => sub { $s_s1->is_equal($s_s2) },
        o => sub { $s_o1->equal($s_o2) },
    },
    is_subset => {
        t => sub { $s_t1->is_subset($s_t2) },
        s => sub { $s_s1->is_subset($s_s2) },
        o => sub { $s_o1->subset($s_o2) },
    },
    is_proper_subset => {
        t => sub { $s_t1->is_proper_subset($s_t2) },
        s => sub { $s_s1->is_proper_subset($s_s2) },
        o => sub { $s_o1->proper_subset($s_o2) },
    },
    is_superset => {
        t => sub { $s_t1->is_superset($s_t2) },
        s => sub { $s_s1->is_superset($s_s2) },
        o => sub { $s_o1->superset($s_o2) },
    },
    is_proper_superset => {
        t => sub { $s_t1->is_proper_superset($s_t2) },
        s => sub { $s_s1->is_proper_superset($s_s2) },
        o => sub { $s_o1->proper_superset($s_o2) },
    },
    is_disjoint => {
        t => sub { $s_t1->is_disjoint($s_t2) },
        s => sub { $s_s1->is_disjoint($s_s2) },
        o => sub { $s_o1->is_disjoint($s_o2) },
    },
    # The $set->contains(@elemets) methods are not identical:
    # Set::Tiny's and Set::Object's contains() returns true if $set contains
    # *all* of @elements
    # Set::Scalar's contains() returns true if $set contains *any* of @elements
    #contains => {
    #    t => sub { $s_t1->contains(@b) },
    #    s => sub { $s_s1->contains(@b) },
    #    o => sub { $s_o1->contains(@b) },
    #},
    difference => {
        t => sub { $s_t1->difference($s_t2) },
        s => sub { $s_s1->difference($s_s2) },
        o => sub { $s_o1->difference($s_o2) },
    },
    union => {
        t => sub { $s_t1->union($s_t2) },
        s => sub { $s_s1->union($s_s2) },
        o => sub { $s_o1->union($s_o2) },
    },
    intersection => {
        t => sub { $s_t1->intersection($s_t2) },
        s => sub { $s_s1->intersection($s_s2) },
        o => sub { $s_o1->intersection($s_o2) },
    },
    symmetric_difference => {
        t => sub { $s_t1->symmetric_difference($s_t2) },
        s => sub { $s_s1->symmetric_difference($s_s2) },
        o => sub { $s_o1->symmetric_difference($s_o2) },
    },
);

print "running benchmarks with sets of size ",
      scalar @a, " and ", scalar @b, "\n";
for my $test (sort keys %tests) {
    print "\n$test:\n";
    cmpthese( -1, {
        'Set::Tiny'   => $tests{$test}{t},
        'Set::Scalar' => $tests{$test}{s},
        'Set::Object' => $tests{$test}{o},
    });
}


#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use SqlBatch::PlanTagFilter;
use Data::Dumper;

my $instruction1 = {
    run_if_tags => {
	tag => 1,
    },
};
my $instruction2 = {
    run_if_not_tags  => {
	not_tag => 1,
    },
};

my $filter0 = SqlBatch::PlanTagFilter->new();
#say Dumper($filter0);

ok(! $filter0->is_allowed_instruction($instruction1),"No tags vs. run-if => disallowed");
ok($filter0->is_allowed_instruction($instruction2),"No tags vs. run-not-if  => allowed");

my $filter1 = SqlBatch::PlanTagFilter->new('tag');
ok($filter1->is_allowed_instruction($instruction1),"tag vs. run-if => allowed");
ok($filter1->is_allowed_instruction($instruction2),"tag vs. run-not-if  => allowed");


my $filter2 = SqlBatch::PlanTagFilter->new('not_tag');
ok($filter2->is_allowed_instruction($instruction1),"not_tag vs. run-if => allowed");
ok(! $filter2->is_allowed_instruction($instruction2),"not_tag vs. run-not-if  => disallowed");

done_testing;

#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Attributes;
use Test::More tests=>1;

subtest 'Registration'=>sub {
	plan tests=>4;
	my $attr=Schedule::Activity::Attributes->new();
	$attr->register('i1',value=>5);
	$attr->register('i1',incr=>2);
	$attr->register('i2',incr=>3);
	$attr->register('b1',type=>'bool',value=>1);
	$attr->register('b2',type=>'bool',set=>1);
	#
	is($$attr{attr}{i1}{value},5,'Integer:  value specified');
	is($$attr{attr}{i2}{value},0,'Integer:  value default');
	is($$attr{attr}{b1}{value},1,'Boolean:  value specified');
	is($$attr{attr}{b2}{value},0,'Boolean:  value default');
};


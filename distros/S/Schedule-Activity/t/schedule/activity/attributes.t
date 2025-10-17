#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Attributes;
use Test::More tests=>2;

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

subtest 'Push/Pop'=>sub {
	plan tests=>4;
	my $attrs=Schedule::Activity::Attributes->new();
	$attrs->register('i1',value=>0);
	$attrs->change('i1',incr=>5);
	is($$attrs{attr}{i1}{value},5,'Attr:  value');
	$attrs->push();
	$attrs->change('i1',incr=>5);
	is($$attrs{attr}{i1}{value},10,'Change:  incr');
	$attrs->pop();
	is($$attrs{attr}{i1}{value},5,'Pop:  value');
	is_deeply($$attrs{stack},[],'Pop clears stack');
};


#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Attribute;
use Test::More tests=>5;

subtest 'init'=>sub {
	plan tests=>9;
	my $attr;
	my $m='Schedule::Activity::Attribute';
	#
	$attr=$m->new();
	is($$attr{type}, 'int','Default:  type');
	is($$attr{value},    0,'Default:  value');
	is($attr->value(),   0,'Default:  ->value');
	#
	$attr=$m->new(value=>5);
	is($$attr{type}, 'int','Value init:  type');
	is($$attr{value},    5,'Value init:  value');
	is($attr->value(),   5,'Value init:  ->value');
	#
	$attr=$m->new(type=>'bool');
	is($$attr{type},'bool','Boolean:  type');
	is($$attr{value},    0,'Boolean:  value');
	is($attr->value(),  '','Boolean:  ->value');
};

subtest 'Validation of options'=>sub {
	plan tests=>2;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>7);
	$attr->validateConfig(set=>1,incr=>2,decr=>3,tm=>5,note=>'note');
	is($attr->value(),7,'Int:  update options');
	#
	$attr=Schedule::Activity::Attribute->new(type=>'bool',value=>0);
	$attr->validateConfig(set=>1,tm=>5,note=>'note');
	is($attr->value(),'','Bool:  update options');
};

subtest 'Change:  Integers'=>sub {
	plan tests=>3;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>0);
	$attr->change(set=>5);  is($attr->value(),5,'set 5');
	$attr->change(incr=>2); is($attr->value(),7,'incr 2');
	$attr->change(decr=>3); is($attr->value(),4,'decr 3');
};

subtest 'Change:  Boolean'=>sub {
	plan tests=>2;
	my $attr=Schedule::Activity::Attribute->new(type=>'bool',value=>0);
	$attr->change(set=>1); ok( $attr->value(),'set 1');
	$attr->change(set=>0); ok(!$attr->value(),'set 0');
};

# t  x
# 0  0
# 1  12
# 3  22
# 7  0
subtest 'Log/avg:  Integer'=>sub {
	plan tests=>2;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>0,tm=>0);
	$attr->change(set=>12,tm=>1);
	$attr->change(set=>22,tm=>3);
	$attr->change(set=> 0,tm=>7);
	my $expect=(1*6+2*17+4*11)/7;
	is_deeply($$attr{log},{0=>0,1=>12,3=>22,7=>0},'Log');
	is($attr->average(),12,'Weighted average');
};


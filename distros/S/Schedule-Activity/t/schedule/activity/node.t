#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Node;
use Test::More tests=>4;

subtest 'validation'=>sub {
	plan tests=>5;
	my $f=\&Schedule::Activity::Node::validate;
	is_deeply([&$f(something=>5)],['Invalid key:  something'],'invalid key');
	is_deeply([&$f(tmmin=>5)],['Incomplete time specification missing:  tmavg tmmax'],'incomplete tm spec');
	is_deeply([&$f(tmmin=>'hi',tmavg=>-5,tmmax=>5)],['Invalid value:  tmmin','Negative value:  tmavg'],'invalid tm values');
	is_deeply([&$f(next=>'name')],['Expected array:  next'],'invalid next');
	is_deeply([&$f(finish=>[])],['Expected name:  finish'],'invalid finish');
	#
	# test that tmmin<tmavg<tmmax
};

subtest 'slack/buffer'=>sub {
	plan tests=>4;
	my $node;
	$node=Schedule::Activity::Node->new(tmmin=>5,tmavg=>15,tmmax=>35);
	is($node->slack(), 10,'Slack, explicit');
	is($node->buffer(),20,'Buffer, explicit');
	$node=Schedule::Activity::Node->new(tmavg=>15);
	is($node->slack(), 0,'Slack, fallback');
	is($node->buffer(),0,'Buffer, fallback');
};

subtest 'next random'=>sub {
	plan tests=>4;
	my $node=Schedule::Activity::Node->new(next=>[qw/one two three/]);
	my %seen=map {$node->nextrandom()=>1} (1..20);
	ok($seen{one},'Random:  one');
	ok($seen{two},'Random:  two');
	%seen=map {$node->nextrandom(not=>'one')=>1} (1..20);
	ok(!$seen{one},'Not one:  one');
	ok( $seen{two},'Not one:  two');
};

subtest 'has next'=>sub {
	plan tests=>2;
	my $node=Schedule::Activity::Node->new(next=>[qw/one two three/]);
	ok( $node->hasnext('one'),'one');
	ok(!$node->hasnext('six'),'six');
};



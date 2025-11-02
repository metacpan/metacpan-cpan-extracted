#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Node;
use Test::More tests=>5;

subtest 'validation'=>sub {
	plan tests=>7;
	my $f=\&Schedule::Activity::Node::validate;
	is_deeply([&$f(something=>5)],['Invalid key:  something'],'invalid key');
	is_deeply([&$f(tmmin=>5)],['Incomplete time specification missing:  tmavg tmmax'],'incomplete tm spec');
	is_deeply([&$f(tmmin=>'hi',tmavg=>-5,tmmax=>5)],['Invalid value:  tmmin','Negative value:  tmavg'],'invalid tm values');
	is_deeply([&$f(tmmin=>5,tmavg=>4,tmmax=>3)],['Invalid:  tmmin>tmavg','Invalid:  tmavg>tmmax'],'tm decreasing sequence');
	is_deeply([&$f(tmmin=>5,tmavg=>5,tmmax=>5)],[],'tm non-increasing sequence');
	is_deeply([&$f(next=>'name')],['Expected array:  next'],'invalid next');
	is_deeply([&$f(finish=>[])],['Expected name:  finish'],'invalid finish');
};

subtest 'defaulting'=>sub {
	plan tests=>6;
	my ($tol,%node)=(1e-6);
	my $f=\&Schedule::Activity::Node::defaulting;
	my $approx=sub {
		my ($x,$y,$label)=@_;
		if(abs($x-$y)<$tol) { $x=$y }
		is($x,$y,$label);
	};
	%node=(tmavg=>20); &$f(\%node); &$approx($node{tmmin},15,'avg->min'); &$approx($node{tmmax},25,'avg->max');
	%node=(tmmax=>25); &$f(\%node); &$approx($node{tmmin},15,'max->min'); &$approx($node{tmavg},20,'max->avg');
	%node=(tmmin=>15); &$f(\%node); &$approx($node{tmavg},20,'min->avg'); &$approx($node{tmmax},25,'min->max');
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
	my %seen=map {$node->nextrandom()=>1} (1..30); # rewrite me to use a countdown loop variable
	ok($seen{one},'Random:  one');
	ok($seen{two},'Random:  two');
	%seen=map {$node->nextrandom(not=>'one')=>1} (1..30); # rewrite me to use a countdown loop variable
	ok(!$seen{one},'Not one:  one');
	ok( $seen{two},'Not one:  two');
};

subtest 'has next'=>sub {
	plan tests=>2;
	my $node=Schedule::Activity::Node->new(next=>[qw/one two three/]);
	ok( $node->hasnext('one'),'one');
	ok(!$node->hasnext('six'),'six');
};



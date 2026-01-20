#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Node;
use Test::More tests=>7;

subtest 'validation'=>sub {
	plan tests=>7;
	my $f=\&Schedule::Activity::Node::validate;
	is_deeply([&$f(something=>5)],['Invalid key:  something'],'invalid key');
	is_deeply([&$f(tmmin=>5)],['Incomplete time specification missing:  tmavg tmmax'],'incomplete tm spec');
	is_deeply([&$f(tmmin=>'hi',tmavg=>-5,tmmax=>5)],['Invalid value:  tmmin','Negative value:  tmavg'],'invalid tm values');
	is_deeply([&$f(tmmin=>5,tmavg=>4,tmmax=>3)],['Invalid:  tmmin>tmavg','Invalid:  tmavg>tmmax'],'tm decreasing sequence');
	is_deeply([&$f(tmmin=>5,tmavg=>5,tmmax=>5)],[],'tm non-increasing sequence');
	is_deeply([&$f(next=>'name')],['Expected array/hash:  next'],'invalid next');
	is_deeply([&$f(finish=>[])],['Expected name:  finish'],'invalid finish');
};

subtest 'defaulting'=>sub {
	plan tests=>7;
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
	%node=(tmmin=>15,tmmax=>35); &$f(\%node);                             &$approx($node{tmavg},25,'min/max->avg');
};

subtest 'next names'=>sub {
	plan tests=>6;
	my $f=\&Schedule::Activity::Node::nextnames;
	is_deeply([sort &$f(undef,undef,{one=>{},two=>{}})],         ['one','two'],'Hash');
	is_deeply([&$f(undef,1,['one','two'])],                      ['one','two'],'Array, names');
	is_deeply([&$f(undef,1,[{keyname=>'one'},{keyname=>'two'}])],['one','two'],'Array, hashes');
	is_deeply([&$f(undef,1,['one',undef,[],{keyname=>'two'}])],  ['one','two'],'Array, mixed, filtered elements');
	is_deeply([&$f(undef,0,['one',undef,[],{keyname=>'two'}])],  ['one',undef,[],{keyname=>'two'}],'Array, mixed, unfiltered');
	is_deeply([&$f({next=>[{keyname=>'one'},{keyname=>'two'}]})],['one','two'],'Object internal {next}');
};

subtest 'next remapping'=>sub {
	plan tests=>4;
	my $f=\&Schedule::Activity::Node::nextremap;
	my %mapping=(
		one=>1, # actual mappings will be references
		two=>2,
		three=>3,
		four=>4,
	);
	is_deeply(&$f({next=>[qw/two four/]},\%mapping),{next=>[2,4]},'Array, elements remapped');
	is_deeply(&$f({next=>[qw/five six/]},\%mapping),{},           'Array, all undefined');
	is_deeply(&$f({next=>{one=>{weight=>1},three=>{weight=>3}} },\%mapping),
		{next=>{one=>{weight=>1,node=>1},three=>{weight=>3,node=>3}} },
		'Hash, {node} populated');
	is_deeply(&$f({next=>{five=>{weight=>1},six=>{weight=>3}} },\%mapping),{},'Hash, all undefined');
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
	plan tests=>5;
	my $node=Schedule::Activity::Node->new(next=>[qw/one two three/]);
	my %seen=map {$node->nextrandom()=>1} (1..30); # rewrite me to use a countdown loop variable
	ok($seen{one},'Random:  one');
	ok($seen{two},'Random:  two');
	%seen=map {$node->nextrandom(not=>'one')=>1} (1..30); # rewrite me to use a countdown loop variable
	ok(!$seen{one},'Not one:  one');
	ok( $seen{two},'Not one:  two');
	#
	# Weighted.  Obviously these numbers are tied and should not be changed.
	my $NB=120; # inner count, gather this many random nodes
	my $NA=184; # outer count, Binomial distribution gives pfail(one==60)<1e-6. (and 173,135 for two/three)
	my %need=(
		one=>60,
		two=>40,
		three=>20,
	);
	my ($steps,$maxouter)=(0,$NA);
	while($steps<$maxouter) {
		%seen=();
		$node=Schedule::Activity::Node->new(next=>{one=>{weight=>3},two=>{weight=>2},three=>{weight=>1}});
		foreach (1..$NB) { $seen{$node->nextrandom()}++ }
		foreach my $k (keys %need) { if(($seen{$k}//0)==$need{$k}) { delete($need{$k}) } }
		if(!%need) { $maxouter=$steps }
		$steps++;
	}
	ok(!%need,"Weighted next ($steps steps)");
};

subtest 'has next'=>sub {
	plan tests=>2;
	my $node=Schedule::Activity::Node->new(next=>[qw/one two three/]);
	ok( $node->hasnext('one'),'one');
	ok(!$node->hasnext('six'),'six');
};



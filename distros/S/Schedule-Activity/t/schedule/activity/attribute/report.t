#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Attributes;
use Schedule::Activity::Attribute::Report;
use Test::More tests=>2;

my $attrs=Schedule::Activity::Attributes->new();
foreach my $attr (
	['boolean',type=>'bool'],
	['counter',type=>'int'],
) {
	my @errors=$attrs->register(@$attr);
	if(@errors) { print join("\n",@errors,''); ... }
}

foreach my $event (
	(map {['boolean',tm=>10*$_,set=>($_%2)]} (0..10)),
	(map {['counter',tm=>$_,set=>$_]}        (0..100)),
) {
	$attrs->change(@$event)
}

subtest 'Grids'=>sub {
	plan tests=>10;
	my $reporter=Schedule::Activity::Attribute::Report->new(attributes=>{$attrs->report()});
	is($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::10::20::30::40::50::60::70::80::90::100::Attribute',
		'0::0::0.5::0.333::0.5::0.4::0.5::0.429::0.5::0.444::0.5::boolean',
		'0::5::10::15::20::25::30::35::40::45::50::counter',
		),'Averages');
	is($reporter->report(
		type  =>'grid',
		values=>'y',
		steps =>10,
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::10::20::30::40::50::60::70::80::90::100::Attribute',
		'0::1::0::1::0::1::0::1::0::1::0::boolean',
		'0::10::20::30::40::50::60::70::80::90::100::counter',
		),'Values');
	is($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>0,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::0::0.5::0.333::0.5::0.4::0.5::0.429::0.5::0.444::0.5::boolean',
		'0::5::10::15::20::25::30::35::40::45::50::counter',
		),'Averages, no header');
	is($reporter->report(
		type  =>'grid',
		values=>'y',
		steps =>10,
		header=>0,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::1::0::1::0::1::0::1::0::1::0::boolean',
		'0::10::20::30::40::50::60::70::80::90::100::counter',
		),'Values, no header');
	is($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>0,
		names =>0,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::0::0.5::0.333::0.5::0.4::0.5::0.429::0.5::0.444::0.5',
		'0::5::10::15::20::25::30::35::40::45::50',
		),'Averages, no header/name');
	is($reporter->report(
		type  =>'grid',
		values=>'y',
		steps =>10,
		header=>0,
		names =>0,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::1::0::1::0::1::0::1::0::1::0',
		'0::10::20::30::40::50::60::70::80::90::100',
		),'Values, no header/name');
	is($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>11,
		header=>0,
		names =>1,
		fmt   =>'%0.5g',
		sep   =>"::",
	),
	join("\n",
		'0::0::0.40909::0.37879::0.43939::0.44545::0.44545::0.47403::0.44805::0.4899::0.44949::0.5::boolean',
		'0::4.5455::9.0909::13.636::18.182::22.727::27.273::31.818::36.364::40.909::45.455::50::counter',
		),'Step size');
	is_deeply($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
		format=>'hash',
	),{"boolean"=>{"avg"=>{"0"=>"0","10"=>"0","20"=>"0\.5","30"=>"0\.333","40"=>"0\.5","50"=>"0\.4","60"=>"0\.5","70"=>"0\.429","80"=>"0\.5","90"=>"0\.444","100"=>"0\.5"}},"counter"=>{"avg"=>{"0"=>"0","10"=>"5","20"=>"10","30"=>"15","40"=>"20","50"=>"25","60"=>"30","70"=>"35","80"=>"40","90"=>"45","100"=>"50"}}},'Averages (hash)');
	is_deeply($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
		format=>'table',
	),[[0,10,20,30,40,50,60,70,80,90,100,'Attribute'],[0,0,0.5,0.333,0.5,0.4,0.5,0.429,0.5,0.444,0.5,'boolean'],[0,5,10,15,20,25,30,35,40,45,50,'counter']],'Averages (table)');
	is($reporter->report(
		type  =>'grid',
		values=>'avg',
		steps =>10,
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>' ',
		format=>'plot',
	),'Time boolean counter
0 0 0
10 0 5
20 0.5 10
30 0.333 15
40 0.5 20
50 0.4 25
60 0.5 30
70 0.429 35
80 0.5 40
90 0.444 45
100 0.5 50'."\n",'Averages (plot)');
};

subtest 'Summary'=>sub {
	plan tests=>6;
	my $reporter=Schedule::Activity::Attribute::Report->new(attributes=>{$attrs->report()});
	is($reporter->report(
		type  =>'summary',
		values=>'avg',
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'Average::Attribute',
		'0.5::boolean',
		'50::counter',
		),'Averages');
	is($reporter->report(
		type  =>'summary',
		values=>'y',
		header=>1,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'Value::Attribute',
		'0::boolean',
		'100::counter',
		),'Values');
	is($reporter->report(
		type  =>'summary',
		values=>'avg',
		header=>0,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0.5::boolean',
		'50::counter',
		),'Averages, no header');
	is($reporter->report(
		type  =>'summary',
		values=>'y',
		header=>0,
		names =>1,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0::boolean',
		'100::counter',
		),'Values, no header');
	is($reporter->report(
		type  =>'summary',
		values=>'avg',
		header=>0,
		names =>0,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0.5',
		'50',
		),'Averages, no header/name');
	is($reporter->report(
		type  =>'summary',
		values=>'y',
		header=>0,
		names =>0,
		fmt   =>'%0.3g',
		sep   =>"::",
	),
	join("\n",
		'0',
		'100',
		),'Values, no header/name');
};

# diag('steps=0/activity boundaries');


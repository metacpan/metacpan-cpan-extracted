#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Annotation;
use Test::More tests=>3;

subtest 'validation'=>sub {
	plan tests=>14;
	my %node;
	my $f=\&Schedule::Activity::Annotation::validate;
	is_deeply([(&$f(something=>5))[0]],          ['Invalid key:  something'],'invalid key');
	is_deeply([(&$f())[0]],                      ['Expected:  message'],'required:  message');
	is_deeply([(&$f(message=>'m'))[0]],          ['Expected regexp:  nodes'],  'required:  nodes');
	is_deeply([(&$f(message=>'m',nodes=>[]))[0]],['Expected regexp:  nodes'],  'required:  nodes as regexp');
	%node=(message=>'m',nodes=>qr/hi/);
	is_deeply([&$f(%node,between=>'h')], ['Invalid value:  between'],  'between:  numeric');
	is_deeply([&$f(%node,p=>'h')],       ['Invalid value:  p'],        'p:        numeric');
	is_deeply([&$f(%node,limit=>'h')],   ['Invalid value:  limit'],    'limit:    numeric');
	is_deeply([&$f(%node,between=>-1)],  ['Negative value:  between'], 'between:  >=0');
	is_deeply([&$f(%node,p=>-1)],        ['Negative value:  p'],       'p:        >=0');
	is_deeply([&$f(%node,limit=>-1)],    ['Negative value:  limit'],   'limit:    >=0');
	is_deeply([&$f(%node,before=>'')],   ['Before invalid structure'], 'before:   hash');
	is_deeply([&$f(%node,before=>{min=>'h'})], ['Invalid value:  before{min}'], 'before{min}:  numeric');
	is_deeply([&$f(%node,before=>{max=>'h'})], ['Invalid value:  before{max}'], 'before{max}:  numeric');
	%node=(%node,between=>120,p=>0.5,limit=>3,before=>{min=>-10,max=>15});
	is_deeply([&$f(%node)],[], 'valid');
};

subtest 'schedule annotation'=>sub {
	plan tests=>6;
	my ($annotation,@notes);
	my @schedule=(
		[  0,{keyname=>'activity1'}],
		[100,{keyname=>'action1'}],
		[200,{keyname=>'action2'}],
		[300,{keyname=>'action3'}],
		[400,{keyname=>'action4'}],
		[500,{keyname=>'endact1'}],
	);
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action[24]/,
		before=>{min=>10,max=>45},
		between=>180,
		p=>1.00,
		limit=>0,
	);
	@notes=$annotation->annotate(@schedule);
	is_deeply(
		[map {$$_[0]} @notes],
		[155,355],
		'Straightforward scheduling');
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action[24]/,
		before=>{min=>10,max=>45},
		between=>220,
		p=>1.00,
		limit=>0,
	);
	@notes=$annotation->annotate(@schedule);
	is_deeply(
		[map {$$_[0]} @notes],
		[155,375],
		'Between shifts back the second');
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action[24]/,
		before=>{min=>10,max=>45},
		between=>180,
		p=>1.00,
		limit=>1,
	);
	@notes=$annotation->annotate(@schedule);
	is($#notes,0,'Limit=1');
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/watermelon/,
		before=>{min=>10,max=>45},
		between=>180,
		p=>1.00,
		limit=>1,
	);
	@notes=$annotation->annotate(@schedule);
	is($#notes,-1,'No matches');
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action[24]/,
		before=>{min=>-10,max=>-45},
		between=>180,
		p=>1.00,
		limit=>0,
	);
	@notes=$annotation->annotate(@schedule);
	is_deeply(
		[map {$$_[0]} @notes],
		[210,410],
		'After');
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action[24]/,
		before=>{min=>30,max=>-30},
		between=>260,
		p=>1.00,
		limit=>0,
	);
	@notes=$annotation->annotate(@schedule);
	is_deeply(
		[map {$$_[0]} @notes],
		[170,430],
		'Before around zero');
	#
};

subtest 'Attributes are reflected'=>sub {
	plan tests=>1;
	my ($annotation,@notes);
	my @schedule=(
		[  0,{keyname=>'activity1'}],
		[100,{keyname=>'action1'}],
		[200,{keyname=>'action2'}],
		[300,{keyname=>'action3'}],
		[400,{keyname=>'action4'}],
		[500,{keyname=>'endact1'}],
	);
	#
	$annotation=Schedule::Activity::Annotation->new(
		message=>'annotation',
		nodes=>qr/action2/,
		before=>{min=>10,max=>45},
		between=>180,
		p=>1.00,
		limit=>1,
		attributes=>{grape=>{incr=>1}},
	);
	@notes=$annotation->annotate(@schedule);
	is_deeply(\@notes,[[155,{message=>'annotation',attributes=>{grape=>{incr=>1}}}]],'Attribute included');
};


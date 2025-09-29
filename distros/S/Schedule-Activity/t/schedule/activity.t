#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity;
use Test::More tests=>4;

subtest 'validation'=>sub {
	plan tests=>2;

	is_deeply(
		{Schedule::Activity::buildSchedule(
			configuration=>{
				node=>{
					'1'=>{
						next=>['3',[],{}],
						finish=>'4',
					},
					'2'=>{},
				},
			},
		)},{error=>['Node 1, Undefined name in array:  next']},'node:  invalid next entry');

	is_deeply(
		{Schedule::Activity::buildSchedule(
			configuration=>{
				node=>{
					'1'=>{
						next=>['2'],
						finish=>'4',
					},
					'2'=>{},
				},
			},
		)},{error=>['Node 1, Undefined name:  finish']},'node:  invalid finish entry');

};

subtest 'Simple scheduling'=>sub {
	plan tests=>5;
	my %schedule;
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>'Begin action 1',
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
			},
			'action 2'=>{
				message=>'Begin action 2',
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['Activity, conclude'],
			},
			'Activity, conclude'=>{
				message=>'Conclude Activity',
				tmmin=>5,tmavg=>5,tmmax=>5,
			},
		},
	);
	%schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[30,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[15,'Begin action 2'],
			[25,'Conclude Activity'],
		],
		'No slack/buffer');
	%schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[32,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[16,'Begin action 2'],
			[27,'Conclude Activity'],
		],
		'With slack');
	%schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[40,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[20,'Begin action 2'],
			[35,'Conclude Activity'],
		],
		'Maximum slack');
	%schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[28,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[14,'Begin action 2'],
			[23,'Conclude Activity'],
		],
		'With buffer');
	%schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[20,'Activity']]);
	is_deeply(
		[map {[$$_[0],$$_[1]{message}]} @{$schedule{activities}}],
		[
			[ 0,'Begin Activity'],
			[ 5,'Begin action 1'],
			[10,'Begin action 2'],
			[15,'Conclude Activity'],
		],
		'Maximum buffer');
};

subtest 'Failures'=>sub {
	plan tests=>2;
	my %schedule;
	my %configuration=(
		node=>{
			Activity=>{
				message=>'Begin Activity',
				next=>['action 1'],
				tmmin=>5,tmavg=>5,tmmax=>5,
				finish=>'Activity, conclude',
			},
			'action 1'=>{
				message=>'Begin action 1',
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['action 2'],
			},
			'action 2'=>{
				message=>'Begin action 2',
				tmmin=>5,tmavg=>10,tmmax=>15,
				next=>['Activity, conclude'],
			},
			'Activity, conclude'=>{
				message=>'Conclude Activity',
				tmmin=>5,tmavg=>5,tmmax=>5,
			},
		},
	);
	eval { %schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[18,'Activity']]) };
	like($@,qr/(?i:excess exceeds slack)/,'Insufficient slack');
	eval { %schedule=Schedule::Activity::buildSchedule(configuration=>\%configuration,activities=>[[42,'Activity']]) };
	like($@,qr/(?i:shortage exceeds buffer)/,'Insufficient buffer');
};

subtest 'cycles'=>sub {
	plan tests=>1;
	my %schedule;
	%schedule=Schedule::Activity::buildSchedule(activities=>[[4321,'root']],configuration=>{node=>{
		'root'=>{finish=>'terminate',next=>['cycle'],tmmin=>0,tmavg=>0,tmmax=>0},
		'cycle'=>{tmmin=>100,tmavg=>200,tmmax=>400,next=>['cycle','terminate']},
		'terminate'=>{tmmin=>0,tmavg=>0,tmmax=>0},
	}});
	ok($#{$schedule{activities}}>10,'Self-cycle');
};

# test, if times are zero, it can get stuck in an infinite loop

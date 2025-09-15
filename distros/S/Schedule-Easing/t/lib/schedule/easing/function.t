#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::Function;
use Test::More tests=>7;

subtest 'Selection'=>sub {
	plan tests=>3*(2)+2;
	my @names=qw/linear power step/;
	my %shapes  =map {$_=>Schedule::Easing::Function::shape($_)}   @names;
	my %unshapes=map {$_=>Schedule::Easing::Function::inverse($_)} @names;
	foreach my $name (@names) { is(ref($shapes{$name}),  'CODE',"Shape:  $name") }
	foreach my $name (@names) { is(ref($unshapes{$name}),'CODE',"Inverse:  $name") }
	is(scalar(keys %{+{map {$_=>1} values(%shapes)}}),  1+$#names,'Shapes have distinct handlers');
	is(scalar(keys %{+{map {$_=>1} values(%unshapes)}}),1+$#names,'Inverses have distinct handlers');
};

subtest 'Linear'=>sub {
	plan tests=>10;
	my $f=Schedule::Easing::Function::shape('linear');
	is(&$f( 1,10,20,100,200),100,'ts<tsA');
	is(&$f(10,10,20,100,200),100,'ts=tsA');
	is(&$f(15,10,20,100,200),150,'ts=mid');
	is(&$f(20,10,20,100,200),200,'ts=tsB');
	is(&$f(25,10,20,100,200),200,'ts>tsB');
	#
	$f=Schedule::Easing::Function::inverse('linear');
	is(&$f(100,10,20,100,200),10,'y=ymin');
	is(&$f(150,10,20,100,200),15,'y=mid');
	is(&$f(200,10,20,100,200),20,'y=ymax');
	ok(!defined(&$f( 50,10,20,100,200)),'y<ymin');
	ok(!defined(&$f(250,10,20,100,200)),'y>ymax');
};

subtest 'Linear decreasing'=>sub {
	plan tests=>12;
	my $f=Schedule::Easing::Function::shape('linear');
	is(&$f( 1,10,20,200,100),200,'ts<tsA');
	is(&$f(10,10,20,200,100),200,'ts=tsA');
	is(&$f(15,10,20,200,100),150,'ts=mid');
	is(&$f(20,10,20,200,100),100,'ts=tsB');
	is(&$f(25,10,20,200,100),100,'ts>tsB');
	#
	$f=Schedule::Easing::Function::inverse('linear');
	is(&$f(200,10,20,200,100),10,'y=ymin');
	is(&$f(120,10,20,200,100),18,'y=120');
	is(&$f(150,10,20,200,100),15,'y=mid');
	is(&$f(180,10,20,200,100),12,'y=180');
	is(&$f(100,10,20,200,100),20,'y=ymax');
	ok(!defined(&$f( 50,10,20,200,100)),'y<yrange');
	ok(!defined(&$f(250,10,20,200,100)),'y>yrange');
};

subtest 'Power'=>sub {
	plan tests=>10;
	my $f=Schedule::Easing::Function::shape('power');
	is(&$f( 1,10,20,100,200,2),100,'ts<tsA');
	is(&$f(10,10,20,100,200,2),100,'ts=tsA');
	is(&$f(15,10,20,100,200,2),125,'ts=mid');
	is(&$f(20,10,20,100,200,2),200,'ts=tsB');
	is(&$f(25,10,20,100,200,2),200,'ts>tsB');
	#
	$f=Schedule::Easing::Function::inverse('power');
	is(&$f(100,10,20,100,200,2),10,'y=ymin');
	is(&$f(125,10,20,100,200,2),15,'y=mid');
	is(&$f(200,10,20,100,200,2),20,'y=ymax');
	ok(!defined(&$f( 50,10,20,100,200,2)),'y<yrange');
	ok(!defined(&$f(250,10,20,100,200,2)),'y>yrange');
};

subtest 'Power decreasing'=>sub {
	plan tests=>10;
	my $f=Schedule::Easing::Function::shape('power');
	is(&$f( 1,10,20,200,100,2),200,'ts<tsA');
	is(&$f(10,10,20,200,100,2),200,'ts=tsA');
	is(&$f(15,10,20,200,100,2),175,'ts=mid');
	is(&$f(20,10,20,200,100,2),100,'ts=tsB');
	is(&$f(25,10,20,200,100,2),100,'ts>tsB');
	#
	$f=Schedule::Easing::Function::inverse('power');
	is(&$f(100,10,20,200,100,2),20,'y=ymin');
	is(&$f(175,10,20,200,100,2),15,'y=mid');
	is(&$f(200,10,20,200,100,2),10,'y=ymax');
	ok(!defined(&$f( 50,10,20,200,100,2)),'y<yrange');
	ok(!defined(&$f(250,10,20,200,100,2)),'y>yrange');
};

subtest 'Step'=>sub {
	plan tests=>44;
	my $f=Schedule::Easing::Function::shape('step');
	is(&$f( 1,10,20,100,200,2),100,'2 steps:  ts<tsA');
	is(&$f(10,10,20,100,200,2),100,'2 steps:  ts=tsA');
	is(&$f(14,10,20,100,200,2),100,'2 steps:  ts<step1');
	is(&$f(15,10,20,100,200,2),150,'2 steps:  ts=step1');
	is(&$f(16,10,20,100,200,2),150,'2 steps:  ts>step1');
	is(&$f(19,10,20,100,200,2),150,'2 steps:  ts<step2');
	is(&$f(20,10,20,100,200,2),200,'2 steps:  ts=step2');
	is(&$f(21,10,20,100,200,2),200,'2 steps:  ts>step2');
	#
	is(&$f(-1, 0,20,100,200,4),100,'4 steps:  ts<tsA');
	is(&$f( 0, 0,20,100,200,4),100,'4 steps:  ts=tsA');
	is(&$f( 4, 0,20,100,200,4),100,'4 steps:  ts<step1');
	is(&$f( 5, 0,20,100,200,4),125,'4 steps:  ts=step1');
	is(&$f( 6, 0,20,100,200,4),125,'4 steps:  ts>step1');
	is(&$f( 9, 0,20,100,200,4),125,'4 steps:  ts<step2');
	is(&$f(10, 0,20,100,200,4),150,'4 steps:  ts=step2');
	is(&$f(11, 0,20,100,200,4),150,'4 steps:  ts>step2');
	is(&$f(14, 0,20,100,200,4),150,'4 steps:  ts<step3');
	is(&$f(15, 0,20,100,200,4),175,'4 steps:  ts=step3');
	is(&$f(16, 0,20,100,200,4),175,'4 steps:  ts>step3');
	is(&$f(19, 0,20,100,200,4),175,'4 steps:  ts<step4');
	is(&$f(20, 0,20,100,200,4),200,'4 steps:  ts=step4');
	is(&$f(21, 0,20,100,200,4),200,'4 steps:  ts>step4');
	#
	$f=Schedule::Easing::Function::inverse('step');
	is(&$f(100,10,20,100,200,2),10,'2 steps inverse:  y=ymin');
	is(&$f(149,10,20,100,200,2),10,'2 steps inverse:  y<step1');
	is(&$f(150,10,20,100,200,2),15,'2 steps inverse:  y=step1');
	is(&$f(151,10,20,100,200,2),15,'2 steps inverse:  y>step1');
	is(&$f(199,10,20,100,200,2),15,'2 steps inverse:  y<step2');
	is(&$f(200,10,20,100,200,2),20,'2 steps inverse:  y=step2');
	ok(!defined(&$f( 50,10,20,100,200,2)),'2 steps inverse:  y<yrange');
	ok(!defined(&$f(201,10,20,100,200,2)),'2 steps inverse:  y>yrange');
	#
	is(&$f(100, 0,20,100,200,4), 0,'4 steps inverse:  y=ymin');
	is(&$f(124, 0,20,100,200,4), 0,'4 steps inverse:  y<step1');
	is(&$f(125, 0,20,100,200,4), 5,'4 steps inverse:  y=step1');
	is(&$f(126, 0,20,100,200,4), 5,'4 steps inverse:  y>step1');
	is(&$f(149, 0,20,100,200,4), 5,'4 steps inverse:  y<step2');
	is(&$f(150, 0,20,100,200,4),10,'4 steps inverse:  y=step2');
	is(&$f(151, 0,20,100,200,4),10,'4 steps inverse:  y>step2');
	is(&$f(174, 0,20,100,200,4),10,'4 steps inverse:  y<step3');
	is(&$f(175, 0,20,100,200,4),15,'4 steps inverse:  y=step3');
	is(&$f(176, 0,20,100,200,4),15,'4 steps inverse:  y>step3');
	is(&$f(199, 0,20,100,200,4),15,'4 steps inverse:  y<step4');
	is(&$f(200, 0,20,100,200,4),20,'4 steps inverse:  y=step4');
	ok(!defined(&$f( 99, 0,20,100,200,4)),'4 steps inverse:  y<yrange');
	ok(!defined(&$f(201, 0,20,100,200,4)),'4 steps inverse:  y>yrange');
};

subtest 'Step decreasing'=>sub {
	plan tests=>28;
	my $f=Schedule::Easing::Function::shape('step');
	is(&$f(-1, 0,20,200,100,4),200,'4 steps:  ts<tsA');
	is(&$f( 0, 0,20,200,100,4),200,'4 steps:  ts=tsA');
	is(&$f( 4, 0,20,200,100,4),200,'4 steps:  ts<step1');
	is(&$f( 5, 0,20,200,100,4),175,'4 steps:  ts=step1');
	is(&$f( 6, 0,20,200,100,4),175,'4 steps:  ts>step1');
	is(&$f( 9, 0,20,200,100,4),175,'4 steps:  ts<step2');
	is(&$f(10, 0,20,200,100,4),150,'4 steps:  ts=step2');
	is(&$f(11, 0,20,200,100,4),150,'4 steps:  ts>step2');
	is(&$f(14, 0,20,200,100,4),150,'4 steps:  ts<step3');
	is(&$f(15, 0,20,200,100,4),125,'4 steps:  ts=step3');
	is(&$f(16, 0,20,200,100,4),125,'4 steps:  ts>step3');
	is(&$f(19, 0,20,200,100,4),125,'4 steps:  ts<step4');
	is(&$f(20, 0,20,200,100,4),100,'4 steps:  ts=step4');
	is(&$f(21, 0,20,200,100,4),100,'4 steps:  ts>step4');
	#
	$f=Schedule::Easing::Function::inverse('step');
	is(&$f(200, 0,20,200,100,4), 0,'4 steps inverse:  y=ymin');
	is(&$f(176, 0,20,200,100,4), 0,'4 steps inverse:  y<step1');
	is(&$f(175, 0,20,200,100,4), 5,'4 steps inverse:  y=step1');
	is(&$f(174, 0,20,200,100,4), 5,'4 steps inverse:  y>step1');
	is(&$f(151, 0,20,200,100,4), 5,'4 steps inverse:  y<step2');
	is(&$f(150, 0,20,200,100,4),10,'4 steps inverse:  y=step2');
	is(&$f(149, 0,20,200,100,4),10,'4 steps inverse:  y>step2');
	is(&$f(126, 0,20,200,100,4),10,'4 steps inverse:  y<step3');
	is(&$f(125, 0,20,200,100,4),15,'4 steps inverse:  y=step3');
	is(&$f(124, 0,20,200,100,4),15,'4 steps inverse:  y>step3');
	is(&$f(101, 0,20,200,100,4),15,'4 steps inverse:  y<step4');
	is(&$f(100, 0,20,200,100,4),20,'4 steps inverse:  y=step4');
	ok(!defined(&$f( 99, 0,20,200,100,4)),'4 steps inverse:  y<yrange');
	ok(!defined(&$f(201, 0,20,200,100,4)),'4 steps inverse:  y>yrange');
};


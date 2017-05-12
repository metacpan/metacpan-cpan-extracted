#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart	= new Project::Gantt(
	description	=>	'Less than an hour',
	mode		=>	'hours',
	file		=>	'lesshrs.png');
my $me		= $chart->addResource(
	name		=>	'Alex');

my $halfHour = $chart->addSubProject(
	description	=>	'1/2 Hour');

$halfHour->addTask(
	description	=>	'Drive home',
	resource	=>	$me,
	start		=>	'2004-08-02 14:00:00',
	end		=>	'2004-08-02 14:12:00');
$halfHour->addTask(
	description	=>	'Put on some food',
	resource	=>	$me,
	start		=>	'2004-08-02 14:13:00',
	end		=>	'2004-08-02 14:17:00');
$halfHour->addTask(
	description	=>	'Quick shower',
	resource	=>	$me,
	start		=>	'2004-08-02 14:18:00',
	end		=>	'2004-08-02 14:30:00');

$chart->addTask(
	description	=>	'Eat lunch',
	resource	=>	$me,
	start		=>	'2004-08-02 14:31:00',
	end		=>	'2004-08-02 14:46:00');
$chart->display();

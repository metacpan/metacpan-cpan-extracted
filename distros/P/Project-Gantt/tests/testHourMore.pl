#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart	= new Project::Gantt(
	description	=>	'More than an hour',
	mode		=>	'hours',
	file		=>	'morehrs.png');

my $me	= $chart->addResource(
	name	=>	'Alex');

my $halfDay = $chart->addSubProject(
	description	=>	'Packing');

$halfDay->addTask(
	description	=>	"Buy Brewer's Yeast",
	resource	=>	$me,
	start		=>	'2004-08-03 10:30:00',
	end		=>	'2004-08-03 11:45:00');
$halfDay->addTask(
	description	=>	'Clean CamelBack',
	resource	=>	$me,
	start		=>	'2004-08-03 12:00:00',
	end		=>	'2004-08-03 14:30:00');
$halfDay->addTask(
	description	=>	'Pack Dive Bag',
	resource	=>	$me,
	start		=>	'2004-08-03 14:31:00',
	end		=>	'2004-08-03 17:00:00');

$chart->addTask(
	description	=>	'Wait for trip',
	resource	=>	$me,
	start		=>	'2004-08-03',
	end		=>	'2004-08-05');
$chart->display();

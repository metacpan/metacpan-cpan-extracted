#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart	= new Project::Gantt(
	description	=>	'Less than a month',
	mode		=>	'months',
	file		=>	'lessmns.png');
my $me	= $chart->addResource(
	name	=>	'Alex');

my $trip = $chart->addSubProject(
	description	=>	'Vacation');

$chart->addTask(
	description	=>	'Work',
	resource	=>	$me,
	start		=>	'2004-08-01',
	end		=>	'2004-08-04');
$trip->addTask(
	description	=>	'Relax',
	resource	=>	$me,
	start		=>	'2004-08-05',
	end		=>	'2004-08-08');
$trip->addTask(
	description	=>	'Go diving',
	resource	=>	$me,
	start		=>	'2004-08-09',
	end		=>	'2004-08-13');
$trip->addTask(
	description	=>	'Live luxuriously',
	resource	=>	$me,
	start		=>	'2004-08-14',
	end		=>	'2004-08-16');
$chart->display();

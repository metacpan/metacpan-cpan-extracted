#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart	= new Project::Gantt(
	description	=>	'More than a day',
	file		=>	'moredys.png');

my $me	= $chart->addResource(
	name	=>	'Alex');

$chart->addTask(
	description	=>	'Work',
	resource	=>	$me,
	start		=>	'2004-08-01',
	end		=>	'2004-08-04');
$chart->addTask(
	description	=>	'Vacation',
	resource	=>	$me,
	start		=>	'2004-08-05',
	end		=>	'2004-08-16');
$chart->addTask(
	description	=>	'Get ready for school',
	resource	=>	$me,
	start		=>	'2004-08-17',
	end		=>	'2004-09-04');
$chart->display();

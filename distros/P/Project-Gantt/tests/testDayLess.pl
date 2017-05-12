#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart	= new Project::Gantt(
	description	=>	'Less than a day',
	mode		=>	'days',
	file		=>	'lessdys.png');

my $me	= $chart->addResource(
	name		=>	'Alex');

my $dayTrip = $chart->addSubProject(
	description	=>	'Trip to the cays');

$chart->addTask(
	description	=>	'Wake up',
	resource	=>	$me,
	start		=>	'2004-08-11 08:00:00',
	end		=>	'2004-08-11 08:30:00');
$chart->addTask(
	description	=>	'Breakfast',
	resource	=>	$me,
	start		=>	'2004-08-11 08:45:00',
	end		=>	'2004-08-11 09:30:00');

$dayTrip->addTask(
	description	=>	'Sail to cays',
	resource	=>	$me,
	start		=>	'2004-08-11 10:15:00',
	end		=>	'2004-08-11 14:30:00');
$dayTrip->addTask(
	description	=>	'Go diving',
	resource	=>	$me,
	start		=>	'2004-08-11 14:45:00',
	end		=>	'2004-08-11 17:00:00');
$chart->display()

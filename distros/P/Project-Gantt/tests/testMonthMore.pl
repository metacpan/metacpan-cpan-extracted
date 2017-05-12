#!/usr/bin/perl -w
use strict;
use Project::Gantt;

my $chart = new Project::Gantt(
	description	=>	'More than a month',
	mode		=>	'months',
	file		=>	'moremns.png');
my $me	= $chart->addResource(
	name	=>	'Alex');

my $moreThanYear = $chart->addSubProject(
	description	=>	'Graduation plan');

$moreThanYear->addTask(
	description	=>	'Fall semester',
	resource	=>	$me,
	start		=>	'2004-09-01',
	end		=>	'2004-12-01');
$moreThanYear->addTask(
	description	=>	'Winter Semester',
	resource	=>	$me,
	start		=>	'2005-01-04',
	end		=>	'2005-01-31');
$moreThanYear->addTask(
	description	=>	'Spring Semester',
	resource	=>	$me,
	start		=>	'2005-02-01',
	end		=>	'2005-05-01');
$moreThanYear->addTask(
	description	=>	'Summer Semester',
	resource	=>	$me,
	start		=>	'2005-06-01',
	end		=>	'2005-06-31');
$moreThanYear->addTask(
	description	=>	'Fall Semester',
	resource	=>	$me,
	start		=>	'2005-09-01',
	end		=>	'2005-12-01');
$chart->display();

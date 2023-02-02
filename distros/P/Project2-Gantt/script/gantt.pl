#!/usr/bin/perl

# a fun, imaginary wednesday
use strict;
use warnings;

use Project2::Gantt;
use Project2::Gantt::Skin;

my $skin= Project2::Gantt::Skin->new(
    doTitle         => 1,
    doSwimLanes     => 1
);

my $gantt = Project2::Gantt->new(
    file            =>      'gantt.png',
    skin            =>      $skin,
    mode            =>      'hours',
    description     =>      'A day in the life'
);

my $john = $gantt->addResource(name => 'John Doe');
my $bruno = $gantt->addResource(name => 'Bruno R');

$gantt->addTask(
    description     =>      'Finish sleep',
    resource        =>      $john,
    start           =>      '2004-07-21 00:00:00',
    end             =>      '2004-07-21 08:30:00');

$gantt->addTask(
    description     =>      'Breakfast/Wakeup',
    resource        =>      $bruno,
    start           =>      '2004-07-21 08:30:00',
    end             =>      '2004-07-21 10:00:00');

my $sub = $gantt->addSubProject(description => 'Important Stuff');

$sub->addTask(
    description     =>      'Contemplate my navel',
    resource        =>      $john,
    start           =>      '2004-07-21 10:00:00',
    end             =>      '2004-07-21 11:00:00');

$gantt->addTask(
    description     =>      'Lunch',
    resource        =>      $john,
    start           =>      '2004-07-21 11:00:00',
    end             =>      '2004-07-21 12:30:00');
$sub->addTask(
    description     =>      'Wonder about life',
    resource        =>      $john,
    start           =>      '2004-07-21 11:00:00',
    end             =>      '2004-07-21 11:22:00');

$gantt->addTask(
    description     =>      'Code for a while',
    resource        =>      $john,
    start           =>      '2004-07-21 12:30:00',
    end             =>      '2004-07-21 17:00:00');

$gantt->addTask(
    description     =>      'Sail',
    resource        =>      $john,
    start           =>      '2004-07-21 17:00:00',
    end             =>      '2004-07-21 20:30:00');

my $project = Project2::Gantt->new(
    file            =>      'project.png',
    skin            =>      $skin,
    mode            =>      'days',
    description     =>      'PROJ-XXXXX Demo Project'
);

my $resource_john   = $project->addResource(name => 'John');
my $resource_jane   = $project->addResource(name => 'Jane');
my $resource_client = $project->addResource(name => 'Client');

$project->addTask(
    description => 'Development (OM)',
    resource    => $resource_jane,
    start       => '2023-01-06',
    end         => '2023-01-18',
    color       => '#26ccbb'
);

$project->addTask(
    description => 'System Integration Testing',
    resource    => $resource_john,
    start       => '2023-01-17',
    end         => '2023-01-19',
    color       => '#43acf2'
);

$project->addTask(
    description => 'User Acceptance Testing',
    resource    => $resource_client,
    start       => '2023-01-19',
    end         => '2023-01-28',
    color       => '#a75eeb'
);

$project->addTask(
    description => 'Promote to Production',
    resource    => $resource_john,
    start       => '2023-02-04 00:00:00',
    end         => '2023-02-05 00:00:00',
    color       => '#d63031'
);

my $sub_project = $project->addSubProject(description => 'Quartet Feature 1');

$sub_project->addTask(
    description => 'Quartet',
    resource    => $resource_jane,
    start       => '2023-02-01 00:00:00',
    end         => '2023-02-03 00:00:00',
    color       => '#d63031'
);
#26ccbb green
#43acf2 blue
#fd9742 orange
#d63031 red
#a75eeb purple

$gantt->write();

$project->write();

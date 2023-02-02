#!/usr/bin/perl

use strict;
use warnings;

use Project2::Gantt;

my $gantt = Project2::Gantt->new(
    file        =>      'gantt.png',
    description =>      'My Project'
);

my $john = $gantt->addResource(name => 'John Doe');
my $jane = $gantt->addResource(name => 'Jane Doe');

$gantt->addTask(
    description => 'Analysis',
    resource    => $john,
    start       => '2023-01-06',
    end         => '2023-01-10'
);

$gantt->addTask(
    description => 'Development',
    resource    => $john,
    start       => '2023-01-13',
    end         => '2023-01-20'
);

$gantt->addTask(
    description => 'Testing',
    resource    => $jane,
    start       => '2023-01-23',
    end         => '2023-01-31'
);

$gantt->addTask(
    description => 'Deployment',
    resource    => $jane,
    start       => '2023-02-07',
    end         => '2023-02-07'
);

$gantt->write();
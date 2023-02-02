#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Directory;

use Project2::Gantt;

use constant FILE => 'gantt-hours.png';

my $dir = Test::Directory->new;

my $path = $dir->path(FILE);

use Data::Dumper;

diag Dumper $dir;
diag Dumper $path;

my $gantt = Project2::Gantt->new(
    description => 'Normal day',
    mode        => 'hours',
    file        => $path,
);

isa_ok($gantt, 'Project2::Gantt', 'Project2::Gantt->new');

my $resource  = $gantt->addResource(name => 'John Doe');

$gantt->addTask(
    description => 'Sleep',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-17 22:00:00',
    end         => '2023-01-18 06:30:00',
);

$gantt->addTask(
    description => 'Shower',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 06:30:00',
    end         => '2023-01-18 07:00:00',
);

$gantt->addTask(
    description => 'Breakfast',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 07:00:00',
    end         => '2023-01-18 07:30:00',
);

$gantt->addTask(
    description => 'Drive to work',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 07:30:00',
    end         => '2023-01-18 08:30:00',
);

$gantt->addTask(
    description => 'Work',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 08:30:00',
    end         => '2023-01-18 12:30:00',
);

$gantt->addTask(
    description => 'Lunch',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 12:30:00',
    end         => '2023-01-18 13:30:00',
);

$gantt->addTask(
    description => 'Work',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 13:30:00',
    end         => '2023-01-18 17:30:00',
);

$gantt->addTask(
    description => 'Drive home',
    resource    => $resource,
    mode        => 'hours',
    start       => '2023-01-18 17:30:00',
    end         => '2023-01-18 18:30:00',
);

my $got = [
    map { $_->description } $gantt->tasks->@*
];

my $expected = [
    'Sleep',
    'Shower',
    'Breakfast',
    'Drive to work',
    'Work',
    'Lunch',
    'Work',
    'Drive home'
];

is_deeply($got,$expected, "Tasks descriptions");

$gantt->write;

$dir->has(FILE, 'Write gantt (hours)');

$dir->remove_files(FILE);

done_testing;

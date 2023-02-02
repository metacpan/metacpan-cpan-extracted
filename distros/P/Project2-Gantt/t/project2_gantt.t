#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Project2::Gantt;

my $gantt = Project2::Gantt->new();

isa_ok($gantt, 'Project2::Gantt', 'Project2::Gantt->new');

my $resource  = $gantt->addResource(name => 'Resource');

isa_ok($resource, 'Project2::Gantt::Resource', 'Project2::Gantt->addResource');

my $subproject = $gantt->addSubProject(description => 'Important Stuff');

isa_ok($subproject, 'Project2::Gantt', 'Project2::Gantt->addSubProject');

$subproject->addTask(
    description => 'Development',
    resource    => $resource,
    start       => '2023-01-06',
    end         => '2023-01-18',
);

is($subproject->tasks->[0]->description, 'Development', 'Add task');

done_testing();

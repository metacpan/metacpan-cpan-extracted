#!/usr/bin/env perl

use strict;
use warnings;

use Project2::Gantt;
use Project2::Gantt::Skin;

my $day = Project2::Gantt->new(
    file            =>      'hourly.png',
    description     =>      'Project-XXXXX Demo Project');

my $john = $day->addResource(name => 'John');

$day->addTask(
    description     =>      'Development',
    resource        =>      $john,
    start           =>      '2023-01-13',
    end             =>      '2023-01-16');

$day->addTask(
    description     =>      'System Integration Testing',
    resource        =>      $john,
    start           =>      '2023-01-16',
    end             =>      '2023-01-23');
#
# my $sub = $day->addSubProject(
#     description     =>      'Important Stuff');
# $sub->addTask(
#     description     =>      'Contemplate my navel',
#     resource        =>      $john,
#     start           =>      '2004-07-21 10:00:00',
#     end             =>      '2004-07-21 11:00:00');
#
# $day->addTask(
#     description     =>      'Lunch',
#     resource        =>      $john,
#     start           =>      '2004-07-21 11:00:00',
#     end             =>      '2004-07-21 12:30:00');
# $sub->addTask(
#     description     =>      'Wonder about life',
#     resource        =>      $john,
#     start           =>      '2004-07-21 11:00:00',
#     end             =>      '2004-07-21 11:22:00');
#
# $day->addTask(
#     description     =>      'Code for a while',
#     resource        =>      $john,
#     start           =>      '2004-07-21 12:30:00',
#     end             =>      '2004-07-21 17:00:00');
#
# $day->addTask(
#     description     =>      'Sail',
#     resource        =>      $john,
#     start           =>      '2004-07-21 17:00:00',
#     end             =>      '2004-07-21 20:30:00');

$day->write;
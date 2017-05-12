#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Script;

my $p = new Panotools::Script;

$p->Image->[0] = new Panotools::Script::Line::Image;
$p->Image->[0]->Set (w => 100, h => 100, f => 0, v => 90,
                     r => 0, p => 0, y => 0, n => '"foo.jpg"');

$p->Image->[1] = new Panotools::Script::Line::Image;
$p->Image->[1]->Set (w => 100, h => 100, f => 0, v => 90,
                     r => 0, p => 0, y => 90, n => '"bar.jpg"');

$p->Control->[0] = new Panotools::Script::Line::Control;
$p->Control->[0]->Set (N => 0, n => 1, X => 100, Y => 0, x => 0, y => 0);

$p->Control->[1] = new Panotools::Script::Line::Control;
$p->Control->[1]->Set (N => 0, n => 1, X => 50, Y => 50, x => 50, y => 50);

ok ($p->Control->[0]->Distance ($p) < 0.00001, 'points are 0 pixel distance');
is ($p->Control->[1]->Distance ($p), 250, 'points are 250 pixel distance');

$p->Transform (10,20,30);

is (int ($p->Control->[0]->Distance ($p)), 0, 'points are 0 pixel distance');
is ($p->Control->[1]->Distance ($p), 250, 'points are 250 pixel distance');


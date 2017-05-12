#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempdir /;
use File::Spec;

my $tempdir = tempdir (CLEANUP => 1);

use Panotools::Script;

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin.pto');

my $image = $p->Image->[1];

# image is 239x320
is ($image->W2, 119.5);
is ($image->a ($p), 0.0);
is ($image->b ($p), -0.0258324);
is ($image->c ($p), 0.0);

my $coor_1 = $image->_inv_radial ($p, [50,50]);
like ($coor_1->[0], '/^49.159907/');
like ($coor_1->[1], '/^49.159907/');

my $coor_2 = $image->_radial ($p, $coor_1);
like ($coor_2->[0], '/^49.99999/');
like ($coor_2->[1], '/^49.99999/');

my $vec = $image->To_Cartesian ($p, [119.5,160]);

$image->{r} = 0;  $image->{p} = 90; $image->{y} = 0;
$vec = $image->To_Cartesian ($p, [119.5,160]);

my $distance = $p->Control->[0]->Distance ($p);

ok ($image->Report);

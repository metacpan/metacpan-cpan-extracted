#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempdir /;
use File::Spec;

my $tempdir = tempdir (CLEANUP => 1);

use_ok ('Panotools::Script');

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin.pto');

$p->Transform (10,20,30);

like ($p->Image->[0]->{r}, '/-3.8642696077/');
like ($p->Image->[0]->{y}, '/-7.517201107/');
like ($p->Image->[0]->{p}, '/21.94771605/');

{
my $tempfile = File::Spec->catfile ($tempdir, '012.txt');
ok ($p->Write ($tempfile), "script written to $tempfile");
}

is (scalar @{$p->Control}, 41, '41 control points');

my $dupes = $p->Duplicates;
is (scalar @{$dupes}, 1, '1 duplicate control point removed');
is (scalar @{$p->Control}, 40, '40 control points remaining');

my $a = $p->Subset (1,2,3);
my $b = $p->Subset (0,1,3,4);

is (scalar @{$a->Image}, 3, 'split 3 images');
is (scalar @{$a->Control}, 19, '19 control points with 3 images');

is (scalar @{$b->Image}, 4, 'split 4 images');
is (scalar @{$b->Control}, 21, '21 control points with 4 images');

$a->Merge ($b);
is (scalar @{$a->Image}, 5, 'merged 5 images');
is (scalar @{$a->Control}, 40, 'merged 40 control points');


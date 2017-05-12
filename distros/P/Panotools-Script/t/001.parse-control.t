#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use_ok ('Panotools::Script::Line::Control');

my $control = new Panotools::Script::Line::Control;

is (%{$control}, 0, 'control points is undef');

$control->Parse ("c n0 N1 x1066.5 y844.333 X239.52 Y804.64 t0 p3\n\n");

is ($control->{n}, 0, 'first image is 0');
is ($control->{N}, 1, 'second image is 1');
is ($control->{x}, 1066.5, 'first image x position is 1066.5');

like ($control->Assemble, '/ N1/', 'second image is 1 written as N1');
like ($control->Assemble, '/ X239.52/', 'second image x position written as X239.52');
unlike ($control->Assemble, '/ p3/', 'bogus p3 parameter didn\'t survive');

is ($control->Packed, '0,1066,844,1,239,804,0', 'packed ok');
$control->Parse ("c N0 n1 X1066.5 Y844.333 x239.52 y804.64 t0");
is ($control->Packed, '0,1066,844,1,239,804,0', 'reverse order packed the same');

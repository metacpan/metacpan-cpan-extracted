#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use_ok ('Panotools::Script::Line::Mode');

my $mode = new Panotools::Script::Line::Mode;

ok ($mode->{g} == '1.0', 'gamma defaults to 1.0');
is ($mode->{i}, '0', 'interpolator defaults to poly3');

$mode->{i} = '4';
is ($mode->{i}, '4', 'interpolator is set to spline64');

$mode->{i} = '0';
is ($mode->{i}, '0', 'interpolator is set to poly3');

$mode->Parse ("m g2.2 i1 b\"some test junk\" p0 f0 t\"some other test junk\"\n\n");

is ($mode->{i}, '1', 'interpolator is set to spline16');
is ($mode->{g}, '2.2', 'gamma is set to 2.2');

$mode->{i} = '4';
$mode->{g} = '1.5';

like ($mode->Assemble, '/ g1.5/', 'gamma 1.5 written as g1.5');
like ($mode->Assemble, '/ i4/', 'interpolator spline64 written as i4');
like ($mode->Assemble, '/ p0/', 'no panorama creation set as p0');
like ($mode->Assemble, '/ f0/', 'fast transform set as f0');
unlike ($mode->Assemble, '/test junk/', 'invalid entries removed');

ok ($mode->Report);

#warn $mode->Assemble;

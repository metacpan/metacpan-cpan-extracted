#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use_ok ('Panotools::Script::Line::ControlMorph');

my $morph = new Panotools::Script::Line::ControlMorph;

is (%{$morph}, 0, 'morph points is undef');

$morph->Parse ("C i0 x1066.5 y844.333 X239.52 Y804.64 p3\n\n");

is ($morph->{i}, 0, 'image is 0');
is ($morph->{x}, 1066.5, 'first image x position is 1066.5');

like ($morph->Assemble, '/ i0/', 'image is 0 written as i0');
like ($morph->Assemble, '/ X239.52/', 'second image x position written as X239.52');
unlike ($morph->Assemble, '/ p3/', 'bogus p3 parameter didn\'t survive');


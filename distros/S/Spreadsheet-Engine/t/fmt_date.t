#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use Spreadsheet::Engine::Sheet;
*fmt = \&Spreadsheet::Engine::Sheet::format_number_for_display;

my %date = (
  y                  => '07',
  yyyy               => 2007,
  m                  => 12,
  mm                 => 12,
  mmm                => 'Dec',
  mmmm               => 'December',
  mmmmm              => 'D',
  d                  => '9',
  dd                 => '09',
  ddd                => 'Sun',
  dddd               => 'Sunday',
  'ddd, d mmmm yyyy' => 'Sun, 9 December 2007',
);

plan tests => scalar keys %date;

while (my ($fmtstr, $result) = each %date) {
  is fmt(39425, 'd', $fmtstr), $result, "$fmtstr => $result";
}


#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM;
use Data::Dumper;

my $tap;
my $expected_tap_lines;
{
  local $/;
  open (TAP, "< t/to_be_normalized.tap") or die "Cannot read t/to_be_normalized.tap";
  $tap = <TAP>;
  close TAP;
}
open (ETAP, "< t/expected_normalized.tap") or die "Cannot read t/expected_normalized.tap";
@$expected_tap_lines = map { chomp; $_ } <ETAP>;
close ETAP;

my $tapdata = TAP::DOM->new( tap => $tap, normalize => 1 );

for my $i (0..$#{$tapdata->{lines}}) {
  my $normalized = $tapdata->{lines}[$i]{normalized};
  my $expected   = $expected_tap_lines->[$i];
  is($normalized, $expected, "normalized vs expected line $i");
}

my @non_test_strings = (
    ' ok foo bar',
    ' not ok foo bar',
    ' something else ok foo bar',
    '---',
    '...',
    ' ---',
    ' ...',
    ' --- ',
    ' ... ',
    'NOT OK foo',
    );
my $i = 0;
foreach my $s (@non_test_strings) {
    is(TAP::DOM::normalize_tap_line($s), $s, "normalization of non-test strings $i");
    $i++;
}

done_testing();

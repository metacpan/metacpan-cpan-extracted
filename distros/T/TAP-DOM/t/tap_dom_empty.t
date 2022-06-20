#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM;
use Data::Dumper;

my $source;
my $tapdom;
my @replacement_lines =
  grep { $_ !~ /#/ } # no diagnostics
  split("\n", $TAP::DOM::noempty_tap);

# completely empty TAP file
$source = 't/empty_tap.tap';

# with 'noempty_tap'
$tapdom = TAP::DOM->new (source => $source, noempty_tap => 1);
is (@{$tapdom->{lines}},              1, "with noempty_tap - count tap lines");
is ($tapdom->{lines}[$_]{raw},
    $replacement_lines[$_],
    "with noempty_tap - replacement document - line $_"
  ) for 0..$#replacement_lines;

# without 'noempty_tap'
$tapdom = TAP::DOM->new (source => $source);
is (@{$tapdom->{lines}||[]},          0, "without noempty_tap - count tap lines");

done_testing();

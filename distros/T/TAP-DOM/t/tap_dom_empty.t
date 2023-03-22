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

# ========== completely empty ==========

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

# ========== no TAP lines ==========

# no TAP lines file
$source = 't/no_tap_lines.tap';

# with 'noempty_tap'
$tapdom = TAP::DOM->new (source => $source, noempty_tap => 1);
is (@{$tapdom->{lines}},                     2,                      "no-tap-lines - with noempty_tap - count lines (without children)");
is ($tapdom->{lines}[-1]{raw},               'pragma +tapdom_error', "no-tap-lines - with noempty_tap - replacement document - line -2");
is ($tapdom->{lines}[-1]{_children}[0]{raw}, '# no tap lines',       "no-tap-lines - with noempty_tap - replacement document - line -1");

# without 'noempty_tap'
$tapdom = TAP::DOM->new (source => $source);
is (@{$tapdom->{lines}||[]},          1, "no-tap-lines - without noempty_tap - count lines");

done_testing();

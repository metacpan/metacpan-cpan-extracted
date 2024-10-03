#! /usr/bin/env perl

use utf8;
use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM;
use Data::Dumper;

my $source;
my $tapdom;

# ========== completely empty ==========

# TAP with illegal characters
$source = 't/illegal-utf8.tap';

# Carful with your editor - binary utf-8 data ahead!
my @replacement_lines = (
  '1..2',
  'ok 1 before�after unicode zero U+0000',
  'ok 2 illegal�char',
);

# The original lines can't be done inline easily
# as they contain illegal utf-8 characters.
my @orig_lines;
{
  open my $SOURCETAP, '<', $source;
  @orig_lines = grep { $_ !~ /^#/ } map { chomp; $_ } <$SOURCETAP>;
  close $SOURCETAP;
}

$tapdom = TAP::DOM->new (source => $source, utf8 => 0);
is (@{$tapdom->{lines}}, 3, "illegal utf8 characters - no utf8 - count tap lines");
is ($tapdom->{lines}[$_]{raw},
    $orig_lines[$_],
    "illegal utf8 characters - no utf8 - no replacement - line $_"
  ) for 0..$#orig_lines;

$tapdom = TAP::DOM->new (source => $source, utf8 => 1);
is (@{$tapdom->{lines}}, 3, "illegal utf8 characters - utf8 - filename - count tap lines");
is ($tapdom->{lines}[$_]{raw},
    $replacement_lines[$_],
    "illegal utf8 characters - utf8 - filename - unicode replacement character - line $_"
  ) for 0..$#replacement_lines;

open my $TAP, '<', $source;
$tapdom = TAP::DOM->new (source => $TAP, utf8 => 1);
is (@{$tapdom->{lines}}, 3, "illegal utf8 characters - utf8 - filehandle - count tap lines");
is ($tapdom->{lines}[$_]{raw},
    $replacement_lines[$_],
    "illegal utf8 characters - utf8 - filehandle - unicode replacement character - line $_"
  ) for 0..$#replacement_lines;

done_testing();

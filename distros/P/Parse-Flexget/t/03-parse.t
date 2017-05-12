#!/usr/bin/perl
use Test::More tests => 1;

use Parse::Flexget qw(flexparse);

my @downloads = flexparse(<DATA>);
is(
  $downloads[0],
  'MythBusters.S08E27.Presidents.Challenge.HDTV.XviD-FOOBAR',
  'Downloaded file parsed',
);


__DATA__
INFO     root        Feed tti_tv filtered 50 entries (0 remains).
INFO     root        Feed sb_tv produced 50 entries.
INFO     root        Feed sb_tv filtered 50 entries (0 remains).
INFO     root        Feed tti_mv produced 50 entries.
INFO     root        Feed tti_mv filtered 50 entries (0 remains).
INFO     root        Feed sb_mv produced 50 entries.
INFO     root        Feed sb_mv filtered 50 entries (0 remains).
INFO     root        Feed tti_tv produced 50 entries.
INFO     root        Feed tti_tv filtered 50 entries (0 remains).
INFO     root        Feed sb_tv produced 50 entries.
INFO     root        Feed sb_tv filtered 50 entries (0 remains).
INFO     root        Feed tti_mv produced 50 entries.
INFO     root        Feed tti_mv filtered 50 entries (0 remains).
INFO     root        Feed sb_mv produced 50 entries.
INFO     root        Feed sb_mv filtered 50 entries (0 remains).
INFO     root        Feed tti_tv produced 50 entries.
INFO     root        Feed tti_tv filtered 50 entries (0 remains).
INFO     root        Feed sb_tv produced 50 entries.
INFO     root        Feed sb_tv filtered 50 entries (0 remains).
INFO     root        Feed tti_mv produced 50 entries.
INFO     root        Feed tti_mv filtered 50 entries (0 remains).
INFO     root        Feed sb_mv produced 50 entries.
INFO     root        Feed sb_mv filtered 50 entries (0 remains).
INFO     root        Feed tti_tv produced 50 entries.
INFO     root        Feed tti_tv filtered 50 entries (0 remains).
INFO     root        Feed sb_tv produced 50 entries.
INFO     root        Feed sb_tv filtered 50 entries (0 remains).
INFO     root        Feed tti_mv produced 50 entries.
INFO     root        Feed tti_mv filtered 50 entries (0 remains).
INFO     root        Feed sb_mv produced 50 entries.
INFO     root        Feed sb_mv filtered 50 entries (0 remains).
INFO     root        Feed tti_tv produced 50 entries.
INFO     root        Feed tti_tv filtered 50 entries (0 remains).
INFO     root        Feed sb_tv produced 50 entries.
INFO     root        Feed sb_tv filtered 50 entries (0 remains).
WARNING  rss         Failed to reach server. Reason: timed out
INFO     root        Feed tti_mv didn't produce any entries. This is likely to be misconfigured or non-functional input.
INFO     root        Feed tti_mv filtered 0 entries (0 remains).
INFO     root        Feed sb_mv produced 50 entries.
INFO     root        Feed sb_mv filtered 50 entries (0 remains).
INFO     root        Feed tti_tv produced 50 entries.
INFO     root        Feed tti_tv filtered 49 entries (1 remains).
INFO     download    Downloading: MythBusters.S08E27.Presidents.Challenge.HDTV.XviD-FOOBAR
INFO     root        Feed sb_tv produced 50 entries.

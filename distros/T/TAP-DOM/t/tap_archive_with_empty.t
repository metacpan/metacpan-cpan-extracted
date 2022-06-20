#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM;
use TAP::DOM::Archive;
use Data::Dumper;

my $source;
my $tapdom;
my @replacement_lines =
  grep { $_ !~ /#/ } # no diagnostics
  split("\n", $TAP::DOM::noempty_tap);

# completely empty .tgz file
$source = 't/empty_tap_archive.tgz';
$tapdom = TAP::DOM::Archive->new (source => $source, noempty_tap => 1);
is (@{$tapdom->{dom}[0]{lines}}, 1, "empty archive with noempty_tap - count tap lines");
is ($tapdom->{dom}[0]{lines}[$_]{raw},
    $replacement_lines[$_],
    "empty archive with noempty_tap - replacement document - line $_"
  ) for 0..$#replacement_lines;

# TARP::Archive with an empty TAP file inside
$source = 't/tap-archive-2-with-empty.tgz';
$tapdom = TAP::DOM::Archive->new (source => $source, noempty_tap => 1);

is (@{$tapdom->{dom}},              5, "count tap docs");
is (@{$tapdom->{meta}{file_order}}, 5, "count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "meta file 3");
is ($tapdom->{meta}{file_order}[4], 't/zero_size.t',        "meta file 4");
is ($tapdom->{dom}[4]{lines}[$_]{raw},
    $replacement_lines[$_],
    "empty tap inside archive with noempty_tap - replacement document - line $_"
  ) for 0..$#replacement_lines;

# again but provide already opened filehandle
open my $source_fh, '<', $source;
$tapdom = TAP::DOM::Archive->new (source => $source_fh, noempty_tap => 1);
is (@{$tapdom->{dom}},              5, "open filehandle - count tap docs");
is (@{$tapdom->{meta}{file_order}}, 5, "open filehandle - count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "open filehandle - meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "open filehandle - meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "open filehandle - meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "open filehandle - meta file 3");
is ($tapdom->{meta}{file_order}[4], 't/zero_size.t',        "open filehandle - meta file 4");
is ($tapdom->{dom}[4]{lines}[$_]{raw},
    $replacement_lines[$_],
    "empty tap inside archive with noempty_tap - open filehandle - replacement document - line $_"
  ) for 0..$#replacement_lines;

# again but provide internal scalar filehandle to already read data
my $source_blob = do { local $/; open my $FH, '<', $source; binmode $FH; <$FH> };
open my $source_blob_fh, '<', \$source_blob;
$tapdom = TAP::DOM::Archive->new (source => $source_blob_fh, noempty_tap => 1);
is (@{$tapdom->{dom}},              5, "internal scalar filehandle - count tap docs");
is (@{$tapdom->{meta}{file_order}}, 5, "internal scalar filehandle - count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "internal scalar filehandle - meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "internal scalar filehandle - meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "internal scalar filehandle - meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "internal scalar filehandle - meta file 3");
is ($tapdom->{meta}{file_order}[4], 't/zero_size.t',        "internal scalar filehandle - meta file 4");
is ($tapdom->{dom}[4]{lines}[$_]{raw},
    $replacement_lines[$_],
    "empty tap inside archive with noempty_tap - internal scalar filehandle - replacement document - line $_"
  ) for 0..$#replacement_lines;

done_testing();

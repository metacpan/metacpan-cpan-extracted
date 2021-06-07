#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM::Archive;
use Data::Dumper;

my $source = 't/tap-archive-1.tgz';

my $tapdom = TAP::DOM::Archive->new (source => $source);

#diag Dumper($tapdom);

is (@{$tapdom->{dom}},              4, "count tap docs");
is (@{$tapdom->{meta}{file_order}}, 4, "count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "meta file 3");

# again but provide already opened filehandle
open my $source_fh, '<', $source;
$tapdom = TAP::DOM::Archive->new (source => $source_fh);
is (@{$tapdom->{dom}},              4, "open filehandle - count tap docs");
is (@{$tapdom->{meta}{file_order}}, 4, "open filehandle - count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "open filehandle - meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "open filehandle - meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "open filehandle - meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "open filehandle - meta file 3");

# again but provide internal scalar filehandle to already read data
my $source_blob = do { local $/; open my $FH, '<', $source; binmode $FH; <$FH> };
open my $source_blob_fh, '<', \$source_blob;
$tapdom = TAP::DOM::Archive->new (source => $source_blob_fh);
is (@{$tapdom->{dom}},              4, "internal scalar filehandle - count tap docs");
is (@{$tapdom->{meta}{file_order}}, 4, "internal scalar filehandle - count meta files");
is ($tapdom->{meta}{file_order}[0], 't/00-tapper-meta.t',   "internal scalar filehandle - meta file 0");
is ($tapdom->{meta}{file_order}[1], 't/00-load.t',          "internal scalar filehandle - meta file 1");
is ($tapdom->{meta}{file_order}[2], 't/tapper_test_meta.t', "internal scalar filehandle - meta file 2");
is ($tapdom->{meta}{file_order}[3], 't/boilerplate.t',      "internal scalar filehandle - meta file 3");

done_testing();

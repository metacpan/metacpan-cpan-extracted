#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;

pod_coverage_ok(
    "Ogg::Vorbis::Decoder",
    { also_private => ['dl_load_flags'] },
    "Ogg::Vorbis::Decoder is covered"
);

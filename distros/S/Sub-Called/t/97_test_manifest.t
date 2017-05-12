#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'Set RELEASE_TESTING=1 to run this test' if not $ENV{RELEASE_TESTING};

eval "use Test::CheckManifest 1.0";
plan skip_all => "Test::CheckManifest 1.0 required" if $@;
ok_manifest();

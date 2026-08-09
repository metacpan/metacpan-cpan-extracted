#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author test; set RELEASE_TESTING to run';
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest({ filter => [qr/\.git/, qr/^blib/, qr/\.o$/, qr/\.bs$/,
                         qr/Queue\.c$/, qr/^Makefile$/, qr/MYMETA/] });

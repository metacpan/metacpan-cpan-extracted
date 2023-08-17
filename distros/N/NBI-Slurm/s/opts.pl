#!/usr/bin/env perl
use v5.12;
use Data::Dumper;
# add to library ../lib/
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use NBI::Slurm;

my $opt = NBI::Opts->new(
    -queue => "nbi-short",
    -threads => 1,
    -memory => "12Gb",
    -time   => "1d 88h",
    -tmpdir => "/tmp"
);

print Dumper $opt;
print STDERR $opt->view();
print STDERR $opt->header();

#!/usr/bin/perl
use lib 't/auxlib';
use Test::JMM;
use warnings;
use strict;
use Pod::Inherit;
use Test::More 'no_plan';
use Test::Differences;
use Test::Warn;

use lib 't/lib';
my $pi = Pod::Inherit->new({
                            input_files => 't/lib/not_ours.pm',
                           });
warning_like {$pi->write_pod();}
  qr/not_ours\.pod already exists, and it doesn't look like we generated it\.  Skipping this file/, "Got the warning";
my $orig = do {local (@ARGV, $/) = "t/lib/not_ours.pod"; scalar <>};
eq_or_diff(do {local (@ARGV, $/) = "t/lib/not_ours.pod"; scalar <>},
           $orig,
           "output file doesn't begin with our autogen marker");


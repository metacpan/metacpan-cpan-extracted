#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use File::Slurper qw(read_text);
use Perl::Stripper;
use Test::Differences;
use Test::More 0.98;

my $stripper;

$stripper = Perl::Stripper->new;
eq_or_diff($stripper->strip(read_text("t/data/1.pl")),
           read_text("t/data/1.pl-stripped-default"),
           "default");

$stripper = Perl::Stripper->new(strip_log=>1);
eq_or_diff($stripper->strip(read_text("t/data/1.pl")),
           read_text("t/data/1.pl-stripped-strip_log"),
           "strip_log");

done_testing;

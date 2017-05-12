#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Tangerine;
use File::Find::Rule;
use File::Find::Rule::Perl;
use Time::HiRes qw/gettimeofday tv_interval/;

my @files = File::Find::Rule->perl_file->in('../lib');

my $t0 = [gettimeofday];

for (1..$ARGV[0]//100) {
    for my $file (@files) {
        my $tangerine = Tangerine->new(file => $file, mode => 'all');
        $tangerine->run;
    }
}

print +($ARGV[0]//100)." runs: ".tv_interval($t0)."s\n";

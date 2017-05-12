#!/usr/bin/perl
use warnings;
use strict;
use Test::More 'no_plan';
# use ExtUtils::Manifest 'manifind', 'maniread'; # It's broken.
use Data::Dumper 'Dumper';


my @files = map {chomp; s/\t.*//; $_} do {local @ARGV='MANIFEST'; <>};

for my $file (@files) {
  ok(-e $file, "$file exists");
  
  # allowed to have tabs.
  next if $file eq 'MANIFEST';
  next if $file =~ /\.png$/;

  local @ARGV = $file;
  local $/=undef;
  ok(<> !~ /\t/, "No tabs in $file");
}

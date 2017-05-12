#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author test.  Set $ENV{ TEST_AUTHOR } to enable this test.' unless $ENV{ TEST_AUTHOR };

# Check that all released module files are in
# UNIX text format

use File::Spec;
use File::Find;


my @files;

my $blib = File::Spec->catfile(qw(lib));
find(\&wanted, $blib);
plan tests => scalar @files;
foreach my $file (@files) {
  unix_file_ok($file);
}

sub wanted {
  push @files, $File::Find::name if /\.p(l|m|od)$/;
}

sub unix_file_ok {
  my ($filename) = @_;
  local $/;
  open F, "< $filename"
    or die "Couldn't open '$filename' : $!\n";
  binmode F;
  my $content = <F>;

  my $i;
  my @lines = grep { /\x0D\x0A$/sm } map { sprintf "%s: %s\x0A", $i++, $_ } split /\x0A/, $content;
  unless (is(scalar @lines, 0,"'$filename' contains no windows newlines")) {
    diag $_ for @lines;
  };
  close F;
};

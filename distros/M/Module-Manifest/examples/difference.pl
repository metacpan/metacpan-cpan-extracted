#!/usr/bin/perl -T
#
# examples/difference.pl
#  Determines the differences between a distribution and the MANIFEST.
#
# This module works in similar ways to Test::DistManifest. For production
# use, you may wish to use that instead. In fact, this code was pulled
# from an early version of Test::DistManifest
#
# $Id: difference.pl 4995 2009-01-19 21:05:38Z FREQUENCY@cpan.org $
#
# Copyright (c) 2006-2008 Adam Kennedy, et al.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# The full text of the license can be found in the LICENSE file included with
# this module.

use strict;
BEGIN {
  $^W = 1;
}

use Module::Manifest;

# Parsing command line arguments
use Getopt::Long;

# File management commands
use File::Spec; # Portability
use Cwd 'realpath';
use File::Find (); # Traverse the filesystem tree

=pod

=head1 NAME

difference.pl - Finds differences between your MANIFEST and your current
working directory, excluding the files in MANIFEST.SKIP.

=head1 VERSION

Version 1.0 ($Id: difference.pl 4995 2009-01-19 21:05:38Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('1.0');

=head1 SYNOPSIS

Example use:

  ./difference.pl --manifest MANIFEST --skip MANIFEST.SKIP --verbose
  ./difference.pl --root /path/to/root --manifest MANIFEST

You can also use relative paths like C<../MANIFEST> if you prefer. All
paths will be taken relative to the directory above the current one
by default (since this script is in the C<examples> directory.)

You may also specify a root.

=cut

my $root = realpath(File::Spec->updir);
my $manifile = 'MANIFEST';
my $skipfile = 'MANIFEST.SKIP';
my $verbose = 0;

GetOptions(
  'manifest=s' => \$manifile,
  'skip=s'     => \$skipfile,
  'root=s'     => \$root,
  'verbose'    => \$verbose,
);

my $manifest = Module::Manifest->new;

# Try to parse the MANIFEST and MANIFEST.SKIP files
print "Processing MANIFEST file... " if $verbose;
$manifile = File::Spec->rel2abs($manifile, $root);
eval {
  $manifest->open(manifest => $manifile);
};
if ($@) {
  print "error\n" if $verbose;
  print STDERR 'Failed to parse the MANIFEST: ' . $! . "\n";
  exit();
}
print "success\n" if $verbose;

print "Processing MANIFEST.SKIP file... " if $verbose;
$skipfile = File::Spec->rel2abs($skipfile, $root);
eval {
  $manifest->open(skip     => $skipfile);
};
if ($@) {
  print "error\n" if $verbose;
  print STDERR 'Failed to parse the MANIFEST: ' . $! . "\n";
  exit();
}
print "success\n" if $verbose;

print "Comparing the files and directory...\n\n" if $verbose;

my @files;
# Callback function called by File::Find
sub wanted {
  # Trim off the package root to determine the relative path.
  # This is the relative path from $root
  my $path = File::Spec->abs2rel($File::Find::name, $root);
  # This is the actual path from our Cwd that we have to test
  my $realpath = File::Spec->abs2rel($File::Find::name);

  # Test that the path is a file and then make sure it's not skipped
  if (-f $realpath && !$manifest->skipped($path)) {
    push @files, $path;
  }
  return;
};

# Traverse the directory recursively
File::Find::find({
  wanted            => \&wanted,
  untaint           => 1,
  no_chdir          => 1,
}, $root);

# The two arrays have no duplicates. Thus we loop through them and
# add the result to a hash.
my %seen;
# Allocate buckets for the hash
keys(%seen) = 2 * scalar(@files);
foreach my $path (@files, $manifest->files) {
  $seen{$path}++;
}

my $flag = 1;
foreach my $path (@files) {
  # Skip the path if it was seen twice (the expected condition)
  next if ($seen{$path} == 2);

  # Oh no, we have files in @files not in $manifest->files
  if ($flag == 1) {
    print "The following distribution files are missing in MANIFEST:\n";
    $flag = 0;
  }
  print $path . "\n";
}

# Reset the flag and test $manifest->files now
$flag = 1;
foreach my $path ($manifest->files) {
  # Skip the path if it was seen twice (the expected condition)
  next if ($seen{$path} == 2);

  # Oh no, we have files in $manifest->files not in @files
  if ($flag == 1) {
    print "MANIFEST lists the following missing files:\n";
    $flag = 0;
  }
  print $path . "\n";
}

#!/usr/bin/perl -- -*- mode: cperl -*-

# This script takes maybe an hour to run and builds the sources of
# each perl we know about from the preceding version. From patches 1
# to current. The names of the resulting perls are, of course, built
# upon the previous version, e.g. 5.8.0 becomes 5.7.3@17638

# The program is for demonstration only, it's not needed by the
# Perl::Repository::APC suite.

use strict;
use warnings;

use Perl::Repository::APC;

my $APC = shift or die "Usage: $0 /path/to/APC";

my $apc = Perl::Repository::APC->new($APC);

my $only_wip = 0; # work in progress
my $no_wip = 0;
my $skip = 0;
for my $apcdir ($apc->apcdirs) {
  my($apc_branch,$pver,@patches) = @$apcdir;
  # $skip = 0 if $pver eq "5.7.1";
  my $pfrom = $apc->get_from_version($apc_branch,$patches[-1]);
  print "x" x 13, " apc_branch[$apc_branch] pver[$pver] ", "x" x 13, "\n";
  next if $skip;
  my $system;
  if ($only_wip) {
    my $pto = $apc->get_to_version($apc_branch,$patches[-1]);
    next if $apc->next_in_branch($pto);
  } elsif ($no_wip) {
    my $pto = $apc->get_to_version($apc_branch,$patches[-1]);
    next unless $apc->next_in_branch($pto);
  }
  $system = "buildaperl --branch $apc_branch --remo --noconfigure --start $patches[0] $pfrom\@$patches[-1]";
  local $\ = "\n";
  print "*" x 79;
  print "v" x 79;
  print $system;
  print "^" x 79;
  print "*" x 79;
  system($system)==0 or die;
}


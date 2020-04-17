#!/usr/bin/perl
#
# testing group quota support  -tom Apr/02/1999
#
# This script is in the public domain and can be used and redistributed
# without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

use blib;
use warnings;
use strict;
use Quota;

##
## insert your test case constants here:
##
my $path  = ".";
my $ugid  = 2001;
my $dogrp = 1;
my @setq  = qw(123 124 51 52);

my $typnam = ($dogrp ? "GID" : "UID");

# ----------------------------------------------------------------------------

sub print_quota_result
{
  my ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = @_;

  if (defined $bc) {
    if ($bt) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
      $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
    }
    if ($ft) {
      my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
      $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;
    }

    print "Query results: $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n";
  }
  else {
    print "Query failed: ". Quota::strerr() ."\n";
  }
}

# ----------------------------------------------------------------------------

my $dev = Quota::getqcarg($path);
die "$path: mount point not found\n" unless $dev;
print "Using device/argument \"$dev\"\n";

if(Quota::sync($dev) && ($! != 1)) {
  die "Quota::sync: ".Quota::strerr()."\n";
}

print "Query this fs with $typnam $ugid\n";
my @qtup = Quota::query($dev, $ugid, $dogrp);
print_quota_result(@qtup);

##
##  set quota block & file limits for user
##

print "Setting new quota limits for $typnam $ugid: ". join(",", @setq) ."\n";
if (Quota::setqlim($dev, $ugid, @setq, 1, $dogrp) == 0) {
  print "Quotas set successfully for $typnam $ugid\n";
  print "Reading back new quota limits...\n";
  @qtup = Quota::query($dev, $ugid, $dogrp);
  print_quota_result(@qtup);
  if (@qtup) {
    my ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = @qtup;
    if (($bs != $setq[0]) || ($bh != $setq[1]) ||
        ($fs != $setq[2]) || ($fh != $setq[3])) {
      print "ERROR: result does not match\n";
    }
    else {
      print "OK: results match\n";
    }
  }
}
else {
  print "Failed to set quota limits: ".Quota::strerr()."\n";
}

print "Finally checking quota sync again\n";
Quota::sync($dev) && ($! != 1) && die "Quota::sync: ".Quota::strerr()."\n";

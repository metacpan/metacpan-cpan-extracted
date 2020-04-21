#!/usr/bin/perl
#
# Testing reading and setting 64-bit quota limits.
# This is supported by UFS on FreeBSD
#
# Author: T. Zoerner
#
# This program is in the public domain and can be used and
# redistributed without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

use blib;
use warnings;
use strict;
use Quota;

# set random value beyond 32-bit max.
# double (FP) is the only (portable) way to get 64-bit integer in Perl
my $new_bs = 0x15000 * 65536.0;
my $new_bh = 0x16000 * 65536.0;

my $uid = 32000;
my $path = ".";
my $dogrp = 0;

my $typnam = ($dogrp ? "GID" : "UID");

# Get device from filesystem path
my $dev = Quota::getqcarg($path);
die "$path: mount point not found\n" unless $dev;
print "Using device/argument \"$dev\"\n";

# Get quota for user
my ($bc, $bs, $bh,$bt,$ic, $is, $ih, $it) = Quota::query($dev, $uid, $dogrp);
if (defined $bc) {
  print "CUR $typnam $uid: $bc, $bs, $bh, $bt\n";
}
else {
  print "Failed to query current limits: ".Quota::strerr()."\n";
  $is = $ih = 0;
}

print "SET $typnam $uid: $new_bs, $new_bh\n";

if (Quota::setqlim($dev, $uid, $new_bs, $new_bh, $is,$ih, 1) == 0) {
  print "SET successfully - now reading back\n";
  ($bc, $bs, $bh, $bt, $ic, $is, $ih, $it) = Quota::query($dev, $uid, $dogrp);
  if (defined $bc) {
    print "NEW $typnam $uid: $bc, $bs, $bh, $bt\n";
  }
  else {
    print "Failed to query new limits: ".Quota::strerr()."\n";
  }
}
else {
  warn "Failed to set limits: ".Quota::strerr()."\n";
}

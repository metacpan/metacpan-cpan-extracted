#!/usr/bin/perl
use blib;
use warnings;
use strict;
use Quota;

my $new_bs = 0x15000 * 65536.0;
my $new_bh = 0x16000 * 65536.0;

my $uid = 32000;
my $path = ".";

# Get device from filesystem path
my $dev = Quota::getqcarg($path);
die "$path: mount point not found\n" unless $dev;

# Get quota for user
my ($bc, $bs, $bh,$bt,$ic, $is, $ih, $it)=Quota::query($dev, $uid);
if (defined $bc) {
  print "CUR $uid - $dev - $bc - $bs - $bh - $bt\n";
}
else {
  print "Failed to query current limits: ".Quota::strerr()."\n";
  $is = $ih = 0;
}

print "SET $uid - $dev - $new_bs - $new_bh\n";
if (Quota::setqlim($dev, $uid, $new_bs, $new_bh, $is,$ih, 1) == 0) {
  print "SET successfully - now reading back\n";
  ($bc, $bs, $bh,$bt,$ic, $is, $ih, $it)=Quota::query($dev, $uid);
  if (defined $bc) {
    print "NEW $uid - $dev - $bc - $bs - $bh - $bt\n";
  }
  else {
    print "Failed to query new limits: ".Quota::strerr()."\n";
  }
}
else {
  warn "Failed to set limits: ".Quota::strerr()."\n";
}

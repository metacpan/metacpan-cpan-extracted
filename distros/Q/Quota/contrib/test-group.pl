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
use Quota;

##
## insert your test case constants here:
##
$path  = ".";
$ugid  = 2001;
$dogrp = 1;
@setq  = qw(123 124 51 52);


$typnam = ($dogrp ? "group" : "user");
$dev = Quota::getqcarg($path);
die "$path: mount point not found\n" unless $dev;
print "Using device/argument \"$dev\"\n";

if(Quota::sync($dev) && ($! != 1)) {
    die "Quota::sync: ".Quota::strerr."\n";
}

print "\nQuery this fs with $typnam id $ugid\n";
($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev,$ugid,$dogrp);
if(defined($bc)) {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
  $bt = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $bt;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
  $ft = sprintf("%04d-%02d-%02d/%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min) if $ft;

  print "$typnam usage and limits are $bc ($bs,$bh,$bt) $fc ($fs,$fh,$ft)\n\n";
}
else {
  die "Quota::query($dev,$ugid,$dogrp): ",Quota::strerr,"\n";
}

##
##  set quota block & file limits for user
##

Quota::setqlim($dev, $ugid, @setq, 1, $dogrp) && die Quota::strerr,"\n";
print "$typnam quotas set for id $ugid\n";

Quota::sync($dev) && ($! != 1) && die "Quota::sync: ".Quota::strerr."\n";



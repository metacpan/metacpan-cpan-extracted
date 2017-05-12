#!/usr/bin/perl
use blib;
use Quota;

$new_bs = 0xA00000000;
$new_bh = 0xC00000000;

# Get uid from username
$uid=31979;
# Get device from filesystem path
$dev = Quota::getqcarg("/mnt");
# Get quota for user
($bc, $bs, $bh,$bt,$ic, $is, $ih, $it)=Quota::query($dev, $uid);
print "CUR $uid - $dev - $bc - $bs - $bh - $bt\n";

print "SET $uid - $dev - $new_bs - $new_bh\n";
($bc, $bs, $bh,$bt,$ic, $is, $ih, $it)=Quota::query($dev, $uid);
if (Quota::setqlim($dev, $uid, $new_bs, $new_bh, 10,12, 1) != 0) {
  warn Quota::strerr,"\n";
}

($bc, $bs, $bh,$bt,$ic, $is, $ih, $it)=Quota::query($dev, $uid);
print "NEW $uid - $dev - $bc - $bs - $bh - $bt\n";

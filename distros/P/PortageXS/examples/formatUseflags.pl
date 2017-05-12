#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;


my $pxs=PortageXS->new();

my $package     = "perl";
$package = $ARGV[0] if $ARGV[0];
($package)=$pxs->searchPackage($package,'exact');
if ( not $package ) {
    die "No package found";
}


print "Package ".$package." has been compiled with useflags set: ";
print join(" ",$pxs->formatUseflags($pxs->getUseSettingsOfInstalledPackage($pxs->searchInstalledPackage($package))))."\n";

print "\nMore examples:\n";
print join(" ",$pxs->formatUseflags(qw(abc abc% abc* abc%* -abc -abc* -abc% -abc*%)))."\n";
my $umasked=($pxs->getUsemasksFromProfile())[0];
print join(" ",$pxs->formatUseflags(($umasked,$umasked.'%',$umasked.'*',$umasked.'%*','-'.$umasked,'-'.$umasked.'*','-'.$umasked.'%','-'.$umasked.'*%')))."\n";


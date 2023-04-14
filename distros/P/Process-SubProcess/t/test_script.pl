#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2020-03-21
# @package Test for the SubProcess Module
# @subpackage test_script.pl

# This Script is the Test Script which is run in the Process::SubProcess Module Test
# It generates Output to STDOUT and STDERR
# It returns the EXIT CODE passed as Parameter. Only Integer EXIT CODES are allowed
#
#---------------------------------
# Requirements:
#



use warnings;
use strict;

use Cwd qw(abs_path);

use Time::HiRes qw(gettimeofday);



my $itm = -1;
my $itmstrt = -1;
my $itmend = -1;


$itmstrt = gettimeofday();

print "Start - Time Now: '$itmstrt' s\n";


my $smodule = "";
my $spath = abs_path($0);

my $ipause = $ARGV[0];
my $ierr = $ARGV[1];


($smodule = $spath) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

$ipause = 0 unless(defined $ipause);

if(defined $ierr)
{
  $ierr = 1 unless($ierr =~ qr/^-?\d$/);
}
else
{
  $ierr = 0;
}

print STDERR "script '$smodule' START 0 ERROR\n";

print "script '$smodule' START 0\n";

print "script '$smodule' PAUSE '$ipause' ...\n";

sleep $ipause;

print "script '$smodule' END 1\n";

print STDERR "script '$smodule' END 1 ERROR\n";


$itmend = gettimeofday();

$itm = ($itmend - $itmstrt) * 1000;

print "End - Time Now: '$itmend' s\n";

print "script '$smodule' done in '$itm' ms\n";

print "script '$smodule' EXIT '$ierr'\n";


exit $ierr;

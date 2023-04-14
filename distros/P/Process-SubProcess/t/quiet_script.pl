#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2020-09-06
# @package Test for the SubProcess Module
# @subpackage quiet_script.pl

# This Script is the Test Script which is run in the Process::SubProcess Module Test
# It does not generate any Output
# It returns the EXIT CODE passed as Parameter. Only Integer EXIT CODES are allowed
#
#---------------------------------
# Requirements:
#


use warnings;
use strict;



my $ipause = $ARGV[0];
my $ierr = $ARGV[1];


$ipause = 0 unless(defined $ipause);

if(defined $ierr)
{
  $ierr = 1 unless($ierr =~ qr/^-?\d$/);
}
else
{
  $ierr = 0;
}

sleep $ipause;


exit $ierr;

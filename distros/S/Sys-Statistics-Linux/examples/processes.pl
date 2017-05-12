#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Sys::Statistics::Linux;
use Sys::Statistics::Linux::Processes;

# the default value for the following keys are pages:
#   size, resident, share, trs, drs, lrs, dtp
#
# set PAGES_TO_BYTES to the pagesize of your system if
# you want bytes instead of pages
$Sys::Statistics::Linux::Processes::PAGES_TO_BYTES = 4096;

my $sys  = Sys::Statistics::Linux->new(processes => 1);
sleep 1;
my $stat = $sys->get();

print Dumper($stat->{processes});

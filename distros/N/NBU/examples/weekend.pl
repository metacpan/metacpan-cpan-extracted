#!/usr/local/bin/perl -w
#
# This sample script, weekend.pl, was written to show how you can use
# the NBU modules to find all the tapes used by all the FULL backups from
# a specific weekend.
#
# The script takes 2 optional arguments:
# -d turns on debugging in the NBU modules which basically allows you
# to see which NetBackup commands are invoked during the data gathering
# -a YYYYMMDD sets the effective date of the run, the default being today

#
# The script looks backwards in time for the preceding Friday and analyzes
# the weekend from Friday at 6pm through Monday morning at 6am.

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d?a:', \%opts);

use NBU;
NBU->debug($opts{'d'});

#
# See if the user provided an effective date on the command line
my ($mm, $dd, $yyyy);
if (!$opts{'a'}) {
  my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  $year += 1900;
  $mm = $mon + 1;
  $dd = $mday;
  $yyyy = $year;
}
else {
  $opts{'a'} =~ /^([\d]{4})([\d]{2})([\d]{2})$/;
  $mm = $2;
  $dd = $3;
  $yyyy = $1;
}

#
# The effective date of this weekend analysis run is either the current
# time, or the time specified with the -a option.
# Here we run it back and forth through the timelocal and localtime functions
# to learn what day of the week this is.  The wday variable contains this
# information with 0 being a Sunday
my $effectiveDate = timelocal(0, 0, 0, $dd, $mm-1, $yyyy);
my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($effectiveDate);
print "Effective date for this run is ".localtime($effectiveDate)."\n";

#
# Our analysis would like to start at 6pm local time of the Friday going into the weekend
# First we locate midnight on Friday, i.e. the morning of the Friday we are interested in
my $lastFriday = $effectiveDate - (24 * 60 * 60) * (($wday + 2) % 7);
#
# Now we add 18 hours to get to 6pm on Friday
my $weekendStart = $lastFriday + (18 * 60 * 60);

#
# The weekend ends Monday morning at 6am local time:
my $weekendEnd = $lastFriday + (78 * 60 * 60);

print "Analyzing the weekend from ".localtime($weekendStart)." through ".localtime($weekendEnd)."\n";

#
# Populate our knowledge of all images in the NetBackup environment
# An image is no more than a completed backup job
NBU::Media->populate(1);
NBU::Image->populate;

#
# Create a local list of all these images
my @l = NBU::Image->list;
print "The full image database contains $#l images\n";

#
# Initialize some local counters and an associative array to hold
# all the volumes that were used by the images we are interested in
my %inUse;
my ($total, $totalSize) = (0, 0);

#
# Loop over all the images, picking and choosing only the ones we
# care about
for my $image (@l) {

  # Skip empty images
  next if (!defined($image->size));

  # Images created over the weekend only, please
  next unless (($image->ctime >= $weekendStart) && ($image->ctime < $weekendEnd));

  # Only interested in FULL backups
  next unless ($image->schedule->type eq "FULL");

  # And we can skip disk based volumes as we can't eject those :-)
  next unless ($image->removable);

  #
  # If we get this far we have an image we are interested in

  # Increment the count of images
  $total += 1;

  # Keep track of the amount of data in all the images.  Image sizes are
  # reported in Kilo Bytes, and here we convert to Mega Bytes to keep from
  # overflowing the counter
  my $size = $image->size / 1024;
  $totalSize += $size;

  # And tag the tape volumes that were used by all the fragments
  foreach my $fragment ($image->fragments) {
    my $volume = $fragment->volume;

    #
    # If a policy includes multiple copies, one if the copy's
    # fragments could still have been written to disk...  Skip
    # those volumes here.
    next unless ($volume->removable);

    $inUse{$fragment->volume->id} = $fragment->volume;
  }
}
my $totalGBytes = sprintf("%.2f", $totalSize/1024);
print "$total completed backup images wrote ${totalGBytes}GB of data\n";

#
# Now gather the list of all the volumes we tagged along the way:
my @volumesUsed = (values %inUse); 
print "These images used ".@volumesUsed." volumes\n";


print "As of ".localtime()." these volumes can be found at:\n";
foreach my $volume (@volumesUsed) {
  print " ".$volume->id;

  if (defined($volume->robot)) {
    print " located in robot ".$volume->robot->id;
    print ", slot ".$volume->slot;
  }
  else {
    print " offsite";
  }

  print "\n";
}

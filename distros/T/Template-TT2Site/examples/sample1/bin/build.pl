#!/usr/bin/perl -w
my $RCS_Id = '$Id: build.pl,v 1.1.1.1 2004/03/03 16:12:35 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Tue Mar  2 12:59:15 2004
# Last Modified By: Johan Vromans CPWR
# Last Modified On: Tue Nov 30 16:04:05 2004
# Update Count    : 8
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

################ The Process ################

use File::Spec;

# Find ttree.
my $sep = File::Spec->devnull eq "nul" ? ";" : ":";
my $ttree = "ttree";
foreach my $p ( split($sep, $ENV{PATH}) ) {
    if ( -s "$p/$ttree.pl" ) {
	$ttree = "$p/$ttree.pl";
	last;
    }
    if ( -s "$p/$ttree" && -x _ ) {
	$ttree = "$p/$ttree";
	last;
    }
}
die("Could not find ttree or ttree.pl in PATH\n")
  if $ttree eq "ttree";

# Hand over to ttree.
unshift(@ARGV,
	'-f', File::Spec->catfile('/home/johanv/wrk/tt2site/site', '/etc/ttree.cfg'));

do $ttree or die("ttree did not complete\n");

exit 0;


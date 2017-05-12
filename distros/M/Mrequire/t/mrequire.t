# Do not change this line!
######################### -*- Mode: Perl -*- #########################
##
## File          : Mrequire.t
##
## Author        : Norbert Goevert
## Created On    : Fri Oct 16 13:13:11 1998
## Last Modified : Time-stamp: <1998-10-16 17:19:36 goevert>
##
## Description   : regression tests for Mrequire
##
## $State: Exp $
##
## $Id: mrequire.t,v 1.4 2003/06/13 07:17:40 goevert Exp $
##
## $Log: mrequire.t,v $
## Revision 1.4  2003/06/13 07:17:40  goevert
## *** empty log message ***
##
######################################################################


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mrequire qw(mrequire);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

mrequire 'IO::File';
my $FH = &Mrequire::new('IO::File', 't/mrequire.t', 'r')
  or die "Couldn't read open file `t/mrequire.t': $!\n";

print ref($FH), "\n";
print ref($FH) eq 'IO::File' ? "ok 2\n" : "not ok 2\n";

my $line = $FH->getline;
print $line eq "# Do not change this line!\n" ? "ok 3\n" : "not ok 3\n";



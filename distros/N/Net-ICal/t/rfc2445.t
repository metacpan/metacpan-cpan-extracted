#!/usr/bin/perl -w
# vi:sts=4:shiftwidth=4:syntax=perl
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: rfc2445.t,v 1.10 2001/07/23 14:49:36 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# tests for RFC2445 compliance.
# TODO: these only check for basic validity now; they cannot tell us
#       whether N::I is interpreting the iCal properly. 

use strict;

use Test;
use Carp;
use File::Find;
use Net::ICal;

my @tests;
my $testdata_dir = 'test-data/rfc2445';	# where the iCal sample files live
					# relative from Makefile.PL
sub find_tests {
    return unless /\.ics$/;
    my $file = $File::Find::dir . "/$_";
    push (@tests, $file);
}

BEGIN {
    find ({wanted => \&find_tests}, "test-data/rfc2445");
    plan tests => scalar @tests
}

# test each file and whether it counts as valid iCal or not.
foreach my $test (@tests) {
  test_ical_file($test);
};



#-----------------------------------------------------------------------
# test_ical_file ($filename_with_directory)
# tests a given ical file for compliance. Some files should fail, and we
# know this; some should succeed, and we know this. 
# returns 1 for a successful (DWIM) result, 0 for an unexpected (broken)
# result.
#-----------------------------------------------------------------------
sub test_ical_file {
    my ($file) = @_;
  
    # FIXME: this is not crossplatform; it assumes / is the directory separator.
    my ($rfc, $section, $testnum, $passfail, $testname) =
    $file =~ m|
	rfc([\d]+)/   # find the rfc number
	([/\d]+)      # find the section number
		       # with internal & trailing slashes
	/([\d+])-       # /find the test number
	(\w+)-  # find out if this test is supposed to pass or fail
	(\S+) # find the test name
    |x;
    $section =~ s|/|.|g;
    print "---- rfc $rfc, section $section, test #$testnum($passfail)  $testname\n";
  
    my $cal = new_calendar_from_file($file);
    if ($cal) {
	print join ("\n", @{$cal->errlog}), "\n";
    }

    if ($passfail eq "fail") {
	# we know this iCal is invalid, it should fail
	if (!defined $cal) {
	    ok(1);       # $cal undefined means test-success
	} elsif (@{$cal->errlog} > 0) {
	    ok(1);       # as does a non-empty errlog list
	} else {
	    ok(0);       # otherwise we succeeded, so the test failed
	}
    } elsif ($passfail eq "pass") {
	# we know this iCal is valid, it should pass
	if ($cal and @{$cal->errlog} == 0) {
	    return ok(1); # we succeeded
	} else {
	    return ok(0); # failure
	}
    }
  
}

#-----------------------------------------------------------------------------
# new_calendar_from_file ($filename)
# read in a calendar from a file. Return a Net::ICal object.
#-----------------------------------------------------------------------------
sub new_calendar_from_file {
    my ($filename) = @_;
 
    open CALFILE, "<$filename" or (carp $! and return undef);
 
    local $/;
    undef $/; # slurp mode
    my $cal = Net::ICal::Component->new_from_ical (<CALFILE>) ;
    close CALFILE;
		
    return $cal;
}
	
# END

#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok (can't load)\n" unless $loaded;}
use Net::Hesiod qw( :all );

$loaded = 1;

######################### End of black magic.

# Tests tests (e.g. routines in helpers.pl)
require 't/helpers.pl';

my $holdVERBOSE=$::VERBOSE;
$::VERBOSE=0; #We will be sending non-matching arrays, keep quiet

#No site adjustment should be needed
my @array1 = ( 1,2,3, "four", " five", 6, 7);
my @array2 = ( 1,2,3, "four", " five");
my @array3 = ( 7,6,5,4,3,2,1);
my @array4 = @array1;
my @nullarry = ();
my @nullarry2 = ();
my @null3 = ();
undef @null3;

#1 check for equals
print &are_arrays_equal(\@array1,\@array1)? "ok 1\n" : "not ok 1\n";

#2 check for equals
print &are_arrays_equal(\@array1,\@array4)? "ok 2\n" : "not ok 2\n";

#3 Test for completely unequal, same size
print &are_arrays_equal(\@array1,\@array3)? "not ok 3\n" : "ok 3\n";

#4 different sizes, first longer
print &are_arrays_equal(\@array1,\@array2)? "not ok 4\n" : "ok 4\n";

#5 different sizes, second longer
print &are_arrays_equal(\@array2,\@array1)? "not ok 5\n" : "ok 5\n";

#6 second null
print &are_arrays_equal(\@array1,\@nullarray)? "not ok 6\n" : "ok 6\n";

#7 first null
print &are_arrays_equal(\@nullarray,\@array1)? "not ok 7\n" : "ok 7\n";

#8 both null
print &are_arrays_equal(\@nullarray,\@nullarry2)? "ok 8\n" : "not ok 8\n";

#9 null and undef
print &are_arrays_equal(\@nullarray,\@null3)? "ok 9\n" : "not ok 9\n";

$::VERBOSE= $holdVERBOSE;

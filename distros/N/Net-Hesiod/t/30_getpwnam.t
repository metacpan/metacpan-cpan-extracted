#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok (can't load)\n" unless $loaded;}
use Net::Hesiod qw( :all );

$loaded = 1;

######################### End of black magic.

# Tests getpwnam, getpwuid
require 't/helpers.pl';


#Some site specific data for the testing module
require "t/testdata.pl";

my @nullarry = ();


#Test the raw interface functions
my $context;
hesiod_init($context) &&  die "Unable to hesiod_init: $!\n";

#1 check hesiod_getpwnam/getpwuid
my @pw = hesiod_getpwnam($context,$username);
my $uid = $pw[2]; #Extract uid
my @pw2 = hesiod_getpwuid($context,$uid);
print &are_arrays_equal(\@pw,\@pw2)? "ok 1\n" : "not ok 1\n";

#2 try with bogus username
@pw = hesiod_getpwnam($context,$bogususer);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 2\n" : "not ok 2\n";

#3 try with bogus uid
@pw = hesiod_getpwuid($context,$bogusuid);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 3\n" : "not ok 3\n";

hesiod_end($context);

#Now the same with OO interface
my $hesobj = new Net::Hesiod;
if ( ! defined $hesobj ) { die "Unable to create Net::Hesiod object: $!\n"; }

#4 Make sure OO version matches non-OO version
#@pw2 still has results of valid hesiod_getpwuid
@pw = $hesobj->getpwnam($username);
print &are_arrays_equal(\@pw,\@pw2)? "ok 4\n" : "not ok 4\n";

#5 match reverse
$uid = $pw[2]; #Extract uid
@pw2 = $hesobj->getpwuid($uid);
print &are_arrays_equal(\@pw,\@pw2)? "ok 5\n" : "not ok 5\n";

#6 try bogus username
@pw = $hesobj->getpwnam($bogususer);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 6\n" : "not ok 6\n";

#7 try bogus username
@pw = $hesobj->getpwuid($bogusuid);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 7\n" : "not ok 7\n";

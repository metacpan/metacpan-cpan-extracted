#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok (can't load)\n" unless $loaded;}
use Net::Hesiod qw( :all );

$loaded = 1;

######################### End of black magic.

# Tests getmailhost
require 't/helpers.pl';


#Load Some site specific data for the testing module
require 't/testdata.pl';

my @nullarry = ();

#Test the raw interface functions
my $context;
hesiod_init($context) &&  die "Unable to hesiod_init: $!\n";

#1 check getmailhost
my @pw = hesiod_getmailhost($context,$username);
print &are_arrays_equal(\@pw,\@poresult)? "ok 1\n" : "not ok 1\n";

#2 try with bogus service 
@pw = hesiod_getmailhost($context,$bogususer);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 2\n" : "not ok 2\n";

hesiod_end($context);

#Now the same with OO interface
my $hesobj = new Net::Hesiod;
if ( ! defined $hesobj ) { die "Unable to create Net::Hesiod object: $!\n"; }

#3 check getservbyname
@pw = $hesobj->getmailhost($username);
print &are_arrays_equal(\@pw,\@poresult)? "ok 3\n" : "not ok 3\n";

#4 try bogus name
@pw = $hesobj->getmailhost($bogususer);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 4\n" : "not ok 4\n";

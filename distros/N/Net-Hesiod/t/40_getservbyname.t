#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok (can't load)\n" unless $loaded;}
use Net::Hesiod qw( :all );

$loaded = 1;

######################### End of black magic.

# Tests getservbyname
require 't/helpers.pl';


#Load Some site specific data for the testing module
require "t/testdata.pl";

my @nullarry = ();

#Test the raw interface functions
my $context;
hesiod_init($context) &&  die "Unable to hesiod_init: $!\n";

#1 check getservbyname
my @pw = hesiod_getservbyname($context,$service, $proto);
print &are_arrays_equal(\@pw,\@result)? "ok 1\n" : "not ok 1\n";

#2 try with bogus service 
@pw = hesiod_getservbyname($context,$bogusserv,$proto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 2\n" : "not ok 2\n";

#3 try with bogus proto
@pw = hesiod_getservbyname($context,$service,$bogusproto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 3\n" : "not ok 3\n";

#3 try with bogus serv and proto
@pw = hesiod_getservbyname($context,$bogusserv,$bogusproto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 4\n" : "not ok 4\n";

hesiod_end($context);

#Now the same with OO interface
my $hesobj = new Net::Hesiod;
if ( ! defined $hesobj ) { die "Unable to create Net::Hesiod object: $!\n"; }

#5 check getservbyname
@pw = $hesobj->getservbyname($service, $proto);
print &are_arrays_equal(\@pw,\@result)? "ok 5\n" : "not ok 5\n";

#6 try bogus service 
@pw = $hesobj->getservbyname($bogusserv,$proto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 6\n" : "not ok 6\n";

#7 try bogus proto
@pw = $hesobj->getservbyname($service,$bogusproto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 7\n" : "not ok 7\n";

#8 try bogus service and proto
@pw = $hesobj->getservbyname($bogusserv,$bogusproto);
print &are_arrays_equal(\@pw,\@nullarry)? "ok 8\n" : "not ok 8\n";

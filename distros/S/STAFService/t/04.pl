#!/usr/bin/perl -w
use strict;
use PLSTAF;
use FindBin;
use Config;
use lib "./t";
use TestSubs;

# This test is for seeing that STAF will not crash when trying to load
# a module that does not even compile

my $uselib = $FindBin::Bin;
my $dll = $FindBin::Bin . "/../PERLSRV.$Config{'so'}";

my $handle = STAF::STAFHandle->new("Test_01"); 
if ($handle->{rc} != $STAF::kOk) { 
    print "Error registering with STAF, RC: $handle->{rc}\n"; 
    die $handle->{rc}; 
}
my $result1 = send_request($handle, "SERVICE",
                           "ADD SERVICE FirstTest LIBRARY $dll EXECUTE FailToCompile OPTION USELIB=\"$uselib\"",
                           27, "6:Error constructing service");
my $result2 = send_request($handle, "Ping", "Ping", 0, "PONG");
print "Test - ", (($result1 and $result2) ? "OK" : "NOT OK"), "\n";



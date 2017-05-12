#!/usr/bin/perl -w
use strict;
use PLSTAF;
use FindBin;
use Config;
use lib "./t";
use TestSubs;

# This test is for loading a module that is under a sub directory
# for example: dir::Service

my $uselib = $FindBin::Bin;
my $dll = $FindBin::Bin . "/../PERLSRV.$Config{'so'}";

my $handle = STAF::STAFHandle->new("Test_01"); 
if ($handle->{rc} != $STAF::kOk) { 
    print "Error registering with STAF, RC: $handle->{rc}\n"; 
    die $handle->{rc}; 
}
my $result1 = send_request($handle, "SERVICE",
                           "ADD SERVICE FirstTest LIBRARY $dll EXECUTE dir::Service OPTION USELIB=\"$uselib\"",
                           0, undef);
my $result2 = send_request($handle, "FirstTest", "Ping", 0, "Xong");
my_submit($handle, "SERVICE", "REMOVE SERVICE FirstTest");
print "Test - ", ($result1 and $result2 ? "OK" : "NOT OK"), "\n";



#!/usr/bin/perl -w
use strict;
use PLSTAF;
use FindBin;
use Config;
use lib "./t";
use TestSubs;

# Testing service that dies on 'new'

my $uselib = $FindBin::Bin;
my $dll = $FindBin::Bin . "/../PERLSRV.$Config{'so'}";

my $handle = STAF::STAFHandle->new("Test_01"); 
if ($handle->{rc} != $STAF::kOk) { 
    print "Error registering with STAF, RC: $handle->{rc}\n"; 
    die $handle->{rc}; 
}
my $result1 = send_request($handle, "SERVICE",
                           "ADD SERVICE FirstTest LIBRARY $dll EXECUTE SimpleService OPTION USELIB=\"$uselib\" PARMS=\"die\"",
                           27, "6:Error constructing service");
my $result2 = send_request($handle, "FirstTest", "Ping", 2, "FirstTest");
my $result3 = send_request($handle, "Ping", "Ping", 0, "PONG");
print "Test - ", ($result1 and $result2 and $result3 ? "OK" : "NOT OK"), "\n";



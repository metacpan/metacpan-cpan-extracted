#!/usr/bin/perl -w
use strict;
use PLSTAF;
use FindBin;
use Config;
use lib "./t";
use TestSubs;


my $uselib = $FindBin::Bin;
my $dll = $FindBin::Bin . "/../PERLSRV.$Config{'so'}";

my $handle = STAF::STAFHandle->new("Test_01"); 
if ($handle->{rc} != $STAF::kOk) { 
    print "Error registering with STAF, RC: $handle->{rc}\n"; 
    die $handle->{rc}; 
}
my_submit($handle, "SERVICE", "ADD SERVICE FirstTest LIBRARY $dll EXECUTE DelayedService OPTION USELIB=\"$uselib\"");
for (1..40) {
    my $result = my_async_submit($handle, "FirstTest", "Ping", 0, "Pong");
}
my_submit($handle, "SERVICE", "REMOVE SERVICE FirstTest");
#print "Test - ", ($result ? "OK" : "NOT OK"), "\n";


sub my_async_submit {
    my ($handle, $srv, $request) = @_;
    my $result = $handle->submit2($STAF::STAFHandle::kReqFireAndForget, "local", $srv, $request); 
    if ($result->{rc} != $STAF::kOk) { 
        print "Error getting result, request='$request', RC: $result->{rc}\n"; 
        if (defined($result->{result}) and (length($result->{result}) != 0)) { 
            print "Additional info: $result->{result}\n"; 
        } 
    } 
    return $result->{result}; 
}

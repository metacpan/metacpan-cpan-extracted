#! /usr/bin/env perl

# This file is placed in the public domain.

use lib '..';

use strict;
use warnings;

use SOAP::Clean::XML;
use SOAP::Clean::Client;

print "--------------------------------------------------\n";
print "Setting up server\n";
print "--------------------------------------------------\n";

my $test = 
  new SOAP::Clean::Client(
			  'cgifile:./soap-server.cgi?wsdl'
#			  'cgifile:./soap-server2.cgi?wsdl'
			 )
   ->verbose(2)
#  ->enc_dec_params(1,"private.pem","public2.pem","enc.tmpl","xmlsec")
#  ->dsig_keys(0,"CAkey.pem","CAcert.pem","dsig.tmpl","xmlsec")
  ;

my $a = xml_from_string("<?xml version=\"1.0\"?>"
			."<a>123</a>");

my ($result,$out1,$out2);

########################################################################

print "--------------------------------------------------\n";
print "Usage\n";
print "--------------------------------------------------\n";

my $usage_data = $test->usage();

foreach my $method_name ( sort(keys %$usage_data) ) {
  my $method_data = $$usage_data{$method_name};
  print "$method_name\n";
  foreach my $direction ( "input", "output" ) {
    print "  $direction:\n";
    my $args = $$method_data{$direction};
    foreach my $arg ( keys %$args ) {
      print "    $arg: ",$$args{$arg},"\n";
    }
  }
}

########################################################################

print "--------------------------------------------------\n";
print "Synchronous\n";
print "--------------------------------------------------\n";

($result,$out1,$out2) = $test->Call(0,$a,1,2);

print "result = ", $result,"\n";
print "out1 = ", $out1,"\n";
print "out2 = ", xml_to_string($out2),"\n";

########################################################################

print "--------------------------------------------------\n";
print "Synchronous - test for namespaces in embedded XML\n";
print "--------------------------------------------------\n";

$a = xml_from_string("<?xml version=\"1.0\"?>"
		     ."<a xmlns=\"urn:random\">123</a>");

($result,$out1,$out2) = $test->Call(0,$a,1,2);

print "result = ", $result,"\n";
print "out1 = ", $out1,"\n";
print "out2 = ", xml_to_string($out2),"\n";

########################################################################

print "--------------------------------------------------\n";
print "Asynchronous\n";
print "--------------------------------------------------\n";

my $uid = $test->Spawn(undef,$a,1,2);
while ($test->Running($uid)) {
  print "Waiting...\n";
  sleep 1;
}

($result,$out1,$out2) = $test->Results($uid);

print "result = ", $result,"\n";
print "out1 = ", $out1,"\n";
print "out2 = ", xml_to_string($out2),"\n";

########################################################################

print "--------------------------------------------------\n";
print "Done\n";
print "--------------------------------------------------\n";

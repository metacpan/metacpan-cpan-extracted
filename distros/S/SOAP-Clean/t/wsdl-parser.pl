#! /usr/bin/perl

# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

use lib '..';

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use SOAP::Clean::XML;
use SOAP::Clean::WSDL;

my $wp = new SOAP::Clean::WSDL::Parser;

for my $f ( @ARGV ) {
  print ":::::::::::::::::::: ",$f," ::::::::::::::::::::\n";
  my $wsdl = xml_from_file($f);
  my $service_defs = $wp->parse($wsdl);
  my $port = generate_services($service_defs);
  print Dumper($port);
}

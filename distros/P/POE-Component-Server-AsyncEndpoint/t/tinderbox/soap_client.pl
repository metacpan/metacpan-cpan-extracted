#!/usr/bin/perl

# simple SOAP Server for Testing
# perl Cookbook Recipe 18.14

use SOAP::Lite;
use warnings;
use strict;

my $server = SOAP::Lite
    -> uri('urn://MyTestSOAPClass')
    -> proxy('http://localhost:8081');

my $call = $server->test1();

die $call->faultstring if $call->fault;
print $call->result;


exit;

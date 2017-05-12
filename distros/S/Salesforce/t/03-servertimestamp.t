#!/usr/bin/perl -w

use strict;

use Test;
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 2 }

use Salesforce;

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

my $result = $port->login('username' => $user,'password' => $pass);

$result = $port->getServerTimestamp();
ok(!$result->fault());
ok(defined($result->valueof('//getServerTimestampResponse/result/timestamp')));

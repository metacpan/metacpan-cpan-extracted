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

$result = $port->query('query' => 'select id, firstname, lastname from lead',
		       'limit' => 5);
ok(!$result->fault());

my $i = 0;
foreach my $elem ($result->valueof('//queryResponse/result/records')) {
    ++$i;
}
ok($i,5);

#my $locator = $result->valueof('//queryResponse/result/queryLocator');
#$result = $port->queryMore('queryLocator' => $locator,'limit' => 5);

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

my $result = $port->login('username' => $user, 'password' => $pass);

$result = $port->query('query' => "select Id,Name from Account",
		       'limit' => 1);
my $id = $result->valueof('//queryResponse/result/records')->{'Id'};
my $nm = $result->valueof('//queryResponse/result/records')->{'Name'};

$result = $port->retrieve('fields' => 'Id,Name',
			  'type' => 'Account',
			  'ids' => [ $id ]
			  );

ok($result->valueof('//retrieveResponse/result/type') eq 'Account');
ok($result->valueof('//retrieveResponse/result/Name') eq $nm);

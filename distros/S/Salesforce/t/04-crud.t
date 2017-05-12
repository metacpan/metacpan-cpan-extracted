#!/usr/bin/perl -w

use strict;

use Test;
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 9 }

use Salesforce;

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

my $result = $port->login('username' => $user,'password' => $pass);

$result = $port->create('type' => 'Account',
			'Name' => 'Golden Straw',
			'BillingStreet' => '4322 Haystack Boulevard',
			'BillingCity' => 'Wichita',
			'BillingState' => 'KA',
			'BillingPostalCode' => '87901',
			'BillingCountry' => 'US',
			'Phone' => '666.666.6666',
			'Fax' => '555.555.5555',
			'AccountNumber' => '0000000',
			'Website' => 'www.oz.com',
			'Industry' => 'Farming',
			'NumberOfEmployees' => '40',
			'Ownership' => 'Privately Held',
			'Description' => 'World class hay makers.');
ok(!$result->fault());
my $id = $result->valueof('//createResponse/result/id');
ok(defined($id));

$result = $port->query('query' => "select Name from Account where id='$id'",
		       'limit' => 1);
ok(!$result->fault());
ok($result->valueof('//queryResponse/result/records/Name') eq 'Golden Straw');

$result = $port->update('type' => 'Account',
			'id'   => $id,
			'Name' => 'Byrne Reese, Ltd.');
ok(!$result->fault());
ok($result->valueof('//updateResponse/result/success') eq 'true');

$result = $port->query('query' => "select Name from Account where id='$id'",
		       'limit' => 1);
ok(!$result->fault());
ok($result->valueof('//queryResponse/result/records/Name') eq 'Byrne Reese, Ltd.');

$result = $port->delete($id);
ok(!$result->fault());


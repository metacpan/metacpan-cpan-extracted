#!/usr/bin/perl -w

use strict;

use Test;
#use SOAP::Lite trace => 'debug';
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 5 }

use Salesforce;

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

my $result = $port->login('username' => $user, 'password' => $pass);

$result = $port->getServerTimestamp();
my $start = $result->valueof('//getServerTimestampResponse/result/timestamp');
ok(defined($start));

$result = $port->query('query' => "select Id,Name from Account",
		       'limit' => 1);
ok(!$result->fault());
my $id = $result->valueof('//queryResponse/result/records')->{'Id'};
my $fn = $result->valueof('//queryResponse/result/records')->{'Name'};

sleep(5);

$result = $port->update('type'      => 'Account',
			'id'        => $id,
			'Name' => $fn);

#ok(!$result->fault());
#ok($result->valueof('//updateResponse/result/success') eq 'true');

sleep(5);

$result = $port->getServerTimestamp();
my $end = $result->valueof('//getServerTimestampResponse/result/timestamp');
ok(defined($end));

sleep(5);

$result = $port->getUpdated('type'  => 'Account',
		  'start' => $start,
		  'end'   => $end);

ok(!$result->fault());
ok(defined $result->valueof('//getUpdatedResponse/result'));

#!/usr/bin/perl -w

use strict;

use Test;
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 4 }

use Salesforce;

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

my $result = $port->login('username' => $user, 'password' => $pass);

$result = $port->describeSObject('type' => 'Account');
ok($result->valueof('//describeSObjectResponse/result/createable') eq 'true');
ok(defined($result->valueof('//describeSObjectResponse/result/fields')));
$result = $port->describeGlobal();
ok($result->valueof('//describeGlobalResponse/result/encoding') eq 'UTF-8');
ok($result->valueof('//describeGlobalResponse/result/types') eq 'Account');

#!/usr/bin/perl -w

use strict;

use Test;
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 3 }

use Salesforce;

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

my $result = $port->login('username' => $user, 'password' => $pass);

$result = $port->search('searchString' => 'find {4159017000} in phone fields returning contact(id, phone, firstname, lastname), lead(id, phone, firstname, lastname), account(id, phone, name)');

ok($result->valueof('//searchResponse/result') eq '' || $result->valueof('//searchResponse/result/searchRecords/record/type') eq 'Account');
ok($result->valueof('//searchResponse/result') eq '' || $result->valueof('//searchResponse/result/searchRecords/record/Phone') eq '(415) 901-7000');
ok($result->valueof('//searchResponse/result') eq '' || $result->valueof('//searchResponse/result/searchRecords/record/Name') eq 'sForce');

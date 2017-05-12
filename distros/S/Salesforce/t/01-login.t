#!/usr/bin/perl -w

use strict;

use Test;
use SOAP::Lite;
use vars qw($user $pass);
require 't/sfdc.cfg';

BEGIN { plan tests => 4 }

use Salesforce;
ok(1);
my $service = new Salesforce::SforceService;
ok(1);
my $port = $service->get_port_binding('Soap');
ok(1);
my $result = $port->login('username' => $user,'password' => $pass);
ok($result);

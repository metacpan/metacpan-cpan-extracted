#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use_ok('SRS::EPP::Response::Greeting');

XML::EPP::register_obj_uri(
	"urn:ietf:params:xml:ns:domain-1.0",
	"urn:ietf:params:xml:ns:contact-1.0",
);

XML::EPP::register_ext_uri(
	"urn:ietf:params:xml:ns:secDNS-1.1" => 'dnssec',
);

my $resp = SRS::EPP::Response::Greeting->make_greeting;

my $message = $resp->message;

is($message->server_name, 'localhost', "Servername set to the default");

my $services = $message->services;

is($services->lang->[0], 'en', "English supported");

is($message->dcp->access->access, 'personalAndOther', "DCP access set correctly");

is($services->services->[0], 'urn:ietf:params:xml:ns:contact-1.0', "Correct service 1");
is($services->services->[1], 'urn:ietf:params:xml:ns:domain-1.0', "Correct service 2");

is($services->ext_services->extensions->[0], 'urn:ietf:params:xml:ns:secDNS-1.1', "Correct ext service 1");

done_testing();

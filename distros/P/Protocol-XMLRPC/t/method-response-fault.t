#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use Protocol::XMLRPC::MethodResponse;

eval{Protocol::XMLRPC::MethodResponse->parse()};
ok($@);

my $xml = qq|abcde|;
eval{Protocol::XMLRPC::MethodResponse->parse($xml)};
ok($@);

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><strng>BarFoo</strng></value></param></params></methodResponse>|;
eval{Protocol::XMLRPC::MethodResponse->parse($xml)};
ok($@);

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><array><data><value><i4>12</i4></value><value><string>Foo</string></value><value><bolean>0</boolean></value><value><double>-31.2</double></value></data></array></value></param></params></methodResponse>|;
eval{Protocol::XMLRPC::MethodResponse->parse($xml)};
ok($@);

$xml = qq|<?xml version="1.0"?><methodResponse><fault><value><string>foo</string></value></fault></methodResponse>|;
eval{Protocol::XMLRPC::MethodResponse->parse($xml)};
ok($@);

$xml = qq|<?xml version="1.0"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><int>4</int></value></member><member><name>faultString</name><value><string>Too many parameters.</string></value></member></struct></value></fault></methodResponse>|;
my $res = Protocol::XMLRPC::MethodResponse->parse($xml);

is($res->fault_code, 4);
is($res->fault_string, 'Too many parameters.');
is("$res", $xml);

$res = Protocol::XMLRPC::MethodResponse->new;
$res->fault(-1 => 'unknown error');
$xml = qq|<?xml version="1.0"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><i4>-1</i4></value></member><member><name>faultString</name><value><string>unknown error</string></value></member></struct></value></fault></methodResponse>|;
is($res->fault_code, -1);
is($res->fault_string, 'unknown error');
is("$res", $xml);

$res = Protocol::XMLRPC::MethodResponse->new_fault(-1 => 'unknown error');
$xml = qq|<?xml version="1.0"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><i4>-1</i4></value></member><member><name>faultString</name><value><string>unknown error</string></value></member></struct></value></fault></methodResponse>|;
is($res->fault_code, -1);
is($res->fault_string, 'unknown error');
is("$res", $xml);

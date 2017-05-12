#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

my $class = 'Protocol::XMLRPC::MethodCall';

use_ok($class);

my $method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
is("$method_call", qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params></params></methodCall>|);

$method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
$method_call->add_param('');
is("$method_call", qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><string></string></value></param></params></methodCall>|);

$method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
$method_call->add_param(0);
is("$method_call", qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><i4>0</i4></value></param></params></methodCall>|);

$method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
$method_call->add_param('foo');
is("$method_call", qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><string>foo</string></value></param></params></methodCall>|);

$method_call = Protocol::XMLRPC::MethodCall->new(name => 'foo.bar');
$method_call->add_param(123);
is("$method_call", qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><i4>123</i4></value></param></params></methodCall>|);

eval{$class->parse()};
ok($@);
eval{$class->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><int>foo</int></value></param></params></methodCall>|)};
ok($@);
eval{$class->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><double>foo</double></value></param></params></methodCall>|)};
ok($@);
eval{$class->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><boolean>foo</boolean></value></param></params></methodCall>|)};
ok($@);
eval{$class->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><dateTime.iso8601>foo</dateTime.iso8601></value></param></params></methodCall>|)};
ok($@);
eval{$class->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><base64>@??%*</base64></value></param></params></methodCall>|)};
ok($@);

$method_call = Protocol::XMLRPC::MethodCall->parse(qq|<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><string>foo</string></value></param></params></methodCall>|);
ok($method_call);
is($method_call->name, 'foo.bar');

is(@{$method_call->params}, 1);
is($method_call->params->[0]->value, 'foo');

$method_call = Protocol::XMLRPC::MethodCall->parse(<<'EOF');
<?xml version="1.0"?>
<methodCall>
<methodName>test</methodName>
<params>
<param>
<value><int>0</int></value>
</param>
</params>
</methodCall>
EOF
is($method_call->name, 'test');
is($method_call->params->[0]->value, 0);
is(@{$method_call->params}, 1);

#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 36;

use Protocol::XMLRPC::MethodResponse;

eval { Protocol::XMLRPC::MethodResponse->parse };
ok($@);

my $xml = qq|<?xml version="1.0"?><methodResponse><params><param><value>FooBar</value></param></params></methodResponse>|;
my $res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, 'FooBar');
is("$res", qq|<?xml version="1.0"?><methodResponse><params><param><value><string>FooBar</string></value></param></params></methodResponse>|);
is($res->value, 'FooBar');

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><string>BarFoo</string></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, 'BarFoo');
is("$res", $xml);
is($res->value, 'BarFoo');

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><boolean>false</boolean></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, 'false');
is("$res", $xml);
is($res->value, 'false');

$xml = q|<?xml version="1.0"?><methodResponse><params><param><value><i4>123</i4></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, '123');
is("$res", $xml);
is($res->value, '123');

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><int>321</int></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, '321');
is("$res", $xml);
is($res->value, '321');

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><dateTime.iso8601>19980717T14:08:55</dateTime.iso8601></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is($res->param->value, '900684535');
is("$res", $xml);
is($res->value, '900684535');

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><array><data><value><i4>12</i4></value><value><string>Foo</string></value><value><boolean>false</boolean></value><value><double>-31.2</double></value></data></array></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is_deeply($res->param->value, [12, 'Foo', 'false', -31.2]);
is("$res", $xml);
is_deeply($res->value, ['12', 'Foo', 'false', -31.2]);

$xml = qq|<?xml version="1.0"?><methodResponse><params><param><value><struct><member><name>fooBar</name><value><i4>18</i4></value></member><member><name>barFoo</name><value><string>foo</string></value></member><member><name>bool</name><value><boolean>false</boolean></value></member></struct></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is_deeply($res->param->value, {fooBar => 18, barFoo => 'foo', bool => 'false'});
is("$res", $xml);
is_deeply($res->value, {fooBar => 18, barFoo => 'foo', bool => 'false'});

$res = Protocol::XMLRPC::MethodResponse->new(123);
is("$res", qq|<?xml version="1.0"?><methodResponse><params><param><value><i4>123</i4></value></param></params></methodResponse>|);
is($res->param->value, 123);
is($res->value, 123);

$res = Protocol::XMLRPC::MethodResponse->new([]);
is("$res", qq|<?xml version="1.0"?><methodResponse><params><param><value><array><data></data></array></value></param></params></methodResponse>|);
is_deeply($res->param->value, []);
is_deeply($res->value, []);

$res = Protocol::XMLRPC::MethodResponse->new({});
is("$res", qq|<?xml version="1.0"?><methodResponse><params><param><value><struct></struct></value></param></params></methodResponse>|);
is_deeply($res->param->value, {});
is_deeply($res->value, {});

$xml =
  qq|<?xml version="1.0"?><methodResponse><params><param><value></value></param></params></methodResponse>|;
$res = Protocol::XMLRPC::MethodResponse->parse($xml);
is_deeply($res->value, '');

$res = Protocol::XMLRPC::MethodResponse->parse(<<'EOF');
<?xml version="1.0"?>
<methodResponse>
<params>
<param>
<value>
<struct>
<member><name>id</name><value><string>123</string></value></member>
<member>
<name>children</name><value>
<struct>
<member><name>test</name><value><double>13.99</double></value></member>
<member><name>test2</name><value><string>1234</string></value></member>
</struct>
</value>
</member>
</struct>
</value>
</param>
</params>
</methodResponse>
EOF
is_deeply(
    $res->value,
    {   'children' => {
            'test'  => '13.99',
            'test2' => '1234'
        },
        'id' => '123'
    }
);

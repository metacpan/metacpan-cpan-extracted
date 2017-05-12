#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;

use Protocol::XMLRPC::Value::String;
use Protocol::XMLRPC::Value::Integer;

my $class = 'Protocol::XMLRPC::Value::Array';

use_ok($class);

is($class->type, 'array');

my $array = $class->new();
is($array->to_string, '<array><data></data></array>');

$array->add_data(Protocol::XMLRPC::Value::String->new('bar'));
is($array->to_string, '<array><data><value><string>bar</string></value></data></array>');
is_deeply($array->value, ['bar']);
is(@{$array->data}, 1);
is($array->data->[0]->value, 'bar');

$array->add_data(Protocol::XMLRPC::Value::Integer->new(123));
is($array->to_string, '<array><data><value><string>bar</string></value><value><i4>123</i4></value></data></array>');
is_deeply($array->value, ['bar', 123]);
is(@{$array->data}, 2);
is($array->data->[0]->value, 'bar');
is($array->data->[1]->value, 123);

$array = $class->new(Protocol::XMLRPC::Value::Integer->new(123));
is($array->to_string, '<array><data><value><i4>123</i4></value></data></array>');
is_deeply($array->value, [123]);
is(@{$array->data}, 1);
is($array->data->[0]->value, 123);

$array = $class->new(
    Protocol::XMLRPC::Value::Integer->new(123),
    Protocol::XMLRPC::Value::String->new('foo')
);
is($array->to_string, '<array><data><value><i4>123</i4></value><value><string>foo</string></value></data></array>');
is_deeply($array->value, [123, 'foo']);
is(@{$array->data}, 2);
is($array->data->[0]->value, 123);
is($array->data->[1]->value, 'foo');

$array = $class->new(
    [   Protocol::XMLRPC::Value::Integer->new(123),
        Protocol::XMLRPC::Value::String->new('foo')
    ]
);
is($array->to_string,
    '<array><data><value><i4>123</i4></value><value><string>foo</string></value></data></array>'
);
is_deeply($array->value, [123, 'foo']);
is(@{$array->data}, 2);
is($array->data->[0]->value, '123');
is($array->data->[1]->value, 'foo');

$array = $class->new;
$array->add_data(1);
is($array->to_string,
    '<array><data><value><i4>1</i4></value></data></array>'
);
is_deeply($array->value, [1]);
is(@{$array->data}, 1);
is($array->data->[0]->value, 1);

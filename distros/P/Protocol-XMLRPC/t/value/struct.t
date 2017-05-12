#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;

use Protocol::XMLRPC::Value::String;
use Protocol::XMLRPC::Value::Integer;

my $class = 'Protocol::XMLRPC::Value::Struct';

use_ok($class);

is($class->type, 'struct');

my $struct = $class->new();
is($struct->to_string, '<struct></struct>');

$struct->add_member(foo => Protocol::XMLRPC::Value::String->new('bar'));
is($struct->to_string, '<struct><member><name>foo</name><value><string>bar</string></value></member></struct>');
is_deeply($struct->value, {foo => 'bar'});
is(keys %{$struct->members}, 1);
is($struct->members->{foo}->value, 'bar');

$struct->add_member(bar => Protocol::XMLRPC::Value::Integer->new(123));
is($struct->to_string, '<struct><member><name>foo</name><value><string>bar</string></value></member><member><name>bar</name><value><i4>123</i4></value></member></struct>');
is_deeply($struct->value, {foo => 'bar', bar => 123});
is(keys %{$struct->members}, 2);
is($struct->members->{foo}->value, 'bar');
is($struct->members->{bar}->value, 123);

$struct = $class->new(bar => Protocol::XMLRPC::Value::Integer->new(123));
is($struct->to_string, '<struct><member><name>bar</name><value><i4>123</i4></value></member></struct>');
is_deeply($struct->value, {bar => 123});
is(keys %{$struct->members}, 1);
is($struct->members->{bar}->value, 123);

$struct = $class->new(
    foo => Protocol::XMLRPC::Value::Integer->new(321),
    bar => Protocol::XMLRPC::Value::Integer->new(123)
);
like($struct->to_string, qr|<member><name>foo</name><value><i4>321</i4></value></member>|);
like($struct->to_string, qr|<member><name>bar</name><value><i4>123</i4></value></member>|);
is_deeply($struct->value, {foo => 321, bar => 123});
is(keys %{$struct->members}, 2);
is($struct->members->{foo}->value, 321);
is($struct->members->{bar}->value, 123);

$struct = $class->new(
    {   foo => Protocol::XMLRPC::Value::Integer->new(321),
        bar => Protocol::XMLRPC::Value::Integer->new(123)
    }
);
like($struct->to_string, qr|<member><name>foo</name><value><i4>321</i4></value></member>|);
like($struct->to_string, qr|<member><name>bar</name><value><i4>123</i4></value></member>|);
is_deeply($struct->value, {foo => 321, bar => 123});
is(keys %{$struct->members}, 2);
is($struct->members->{foo}->value, 321);
is($struct->members->{bar}->value, 123);

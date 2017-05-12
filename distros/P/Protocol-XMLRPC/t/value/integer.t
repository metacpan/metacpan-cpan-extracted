#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

my $class = 'Protocol::XMLRPC::Value::Integer';

use_ok($class);

is($class->type, 'int');

my $value = $class->new('12');
is($value->value,     12);
is($value->to_string, '<i4>12</i4>');

$value = $class->new(0);
is($value->to_string, '<i4>0</i4>');

$value = $class->new('12', alias => 'int');
is($value->to_string, '<int>12</int>');

$value = $class->new('-12');
is($value->to_string, '<i4>-12</i4>');

$value = $class->new('-00012');
is($value->to_string, '<i4>-12</i4>');

eval { $value = $class->parse(); };
ok($@);

eval { $value = $class->parse('abc'); };
ok($@);

eval { $value = $class->parse('12.12'); };
ok($@);

ok($class->parse('-12'));

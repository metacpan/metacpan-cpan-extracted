#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

my $class = 'Protocol::XMLRPC::Value::Double';

use_ok($class);

is($class->type, 'double');

my $value = $class->new(12.12);
is($value->to_string, '<double>12.12</double>');

$value = $class->new(-12.12);
is($value->to_string, '<double>-12.12</double>');

$value = $class->new(-12.12);
is($value->to_string, '<double>-12.12</double>');

eval { $value = $class->parse(); };
ok($@);

eval { $value = $class->parse('abc'); };
ok($@);

ok($class->parse('-12.5'));

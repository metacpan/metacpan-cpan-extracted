#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

my $class = 'Protocol::XMLRPC::Value::DateTime';

use_ok($class);

is($class->type, 'datetime');

my $value = $class->new(1247754181);
is($value->to_string,
    '<dateTime.iso8601>20090716T14:23:01</dateTime.iso8601>');

$value = $class->new(0);
is($value->to_string,
    '<dateTime.iso8601>19700101T00:00:00</dateTime.iso8601>');

$value = $class->parse('19700101T00:00:00');
is($value->to_string,
    '<dateTime.iso8601>19700101T00:00:00</dateTime.iso8601>');

eval { $class->parse('abcde'); };
ok($@);

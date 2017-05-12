#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

my $class = 'Protocol::XMLRPC::Value::Base64';

use_ok($class);

is($class->type, 'base64');

my $value = $class->new('foo');
is($value->to_string, "<base64>Zm9v\n</base64>");

$value = $class->parse("Zm9v\n");
is($value->to_string, "<base64>Zm9v\n</base64>");

eval { $class->parse("&^"); };
ok($@);

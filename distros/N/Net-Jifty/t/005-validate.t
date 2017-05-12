#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 31;
use lib 't/lib';
use Net::Jifty::Test;

my $j = Net::Jifty::Test->new();
$j->ua->clear();

my %args = (
    a => 'b',
    c => 'd',
);

$Net::Jifty::Test::content = << "YAML";
---
a: {}
b: {}
c: {}
YAML

$j->validate_action_args(["create", "Jifty::Model::Foo"], %args);
my ($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
$j->ua->clear;
ok(delete $j->action_specs->{"CreateFoo"}, "cached spec");

$Net::Jifty::Test::content = << "YAML";
---
a:
    mandatory: 1
c:
    mandatory: 1
YAML

$j->validate_action_args(["create", "Jifty::Model::Foo"], %args);
($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
$j->ua->clear;
ok(delete $j->action_specs->{"CreateFoo"}, "cached spec");

$Net::Jifty::Test::content = << "YAML";
---
a:
    mandatory: 1
b:
    mandatory: 1
c:
    mandatory: 1
YAML

eval { $j->validate_action_args("CreateFoo", %args) };
like($@, qr/^Mandatory argument 'b' not given for action CreateFoo\. at /);

($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
$j->ua->clear;
ok(delete $j->action_specs->{"CreateFoo"}, "cached spec");

$Net::Jifty::Test::content = << "YAML";
---
a:
    mandatory: 1
b: {}
YAML

eval { $j->validate_action_args(["create", "Jifty::Model::Foo"], %args) };
like($@, qr/^Unknown arguments given for action CreateFoo: c at /);

($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
$j->ua->clear;
ok(delete $j->action_specs->{"CreateFoo"}, "cached spec");


$j = Net::Jifty::Test->new(strict_arguments => 1);
$j->ua->clear();

$Net::Jifty::Test::content = << "YAML";
---
c: {}
YAML

eval { $j->act("CreateFoo", %args) };
like($@, qr/^Unknown arguments given for action CreateFoo: a at /);
($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
$j->ua->clear;
ok(delete $j->action_specs->{"CreateFoo"}, "cached spec");

$Net::Jifty::Test::content = << "YAML";
---
a: {}
c: {}
YAML

$j->create("Jifty::Model::Foo", %args);
($name, $args) = $j->ua->next_call;
is($name, 'get', 'used get for validation');
is($args->[1], 'http://jifty.org/=/action/CreateFoo.yml', 'correct URL');
ok($j->action_specs->{"CreateFoo"}, "cached spec");

($name, $args) = $j->ua->next_call;
is($name, 'request', 'used request for create');
isa_ok($args->[1], 'HTTP::Request', 'argument is an HTTP request');
is($args->[1]->method, 'POST', 'correct method (POST)');
is($args->[1]->uri, 'http://jifty.org/=/model/Jifty%3A%3AModel%3A%3AFoo.yml', 'correct URL');
like($args->[1]->content, qr/^(a=b&c=d|c=d&a=b)$/, 'correct arguments');

$j->ua->clear;

$j->create("Jifty::Model::Foo", %args);
($name, $args) = $j->ua->next_call;
is($name, 'request', 'used cache version of action spec');
isa_ok($args->[1], 'HTTP::Request', 'argument is an HTTP request');
is($args->[1]->method, 'POST', 'correct method (POST)');
is($args->[1]->uri, 'http://jifty.org/=/model/Jifty%3A%3AModel%3A%3AFoo.yml', 'correct URL');
like($args->[1]->content, qr/^(a=b&c=d|c=d&a=b)$/, 'correct arguments');

$j->ua->clear;


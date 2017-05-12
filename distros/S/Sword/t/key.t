#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 15;

use_ok('Sword');

my $library = Sword::Manager->new;
my $module  = $library->get_module('WebstersDict');
my $key     = $module->create_key;
ok($key, 'constructed a key');
isa_ok($key, 'Sword::Key');

$key->set_text('test');
is($key->get_text, 'test', 'got back test text');

my $other_key = $key->clone;
ok($other_key, 'got another key');
isa_ok($other_key, 'Sword::Key');

isnt($$key, $$other_key, 'cloned key is not the same object as the original');

ok($key->equals($other_key), 'cloned key and original are equal');
ok($key->compare($other_key) == 0, 'cloned key and original compare equal');

is($key->get_text, 'test', 'text is test');

$key->set_text('foo');
is($key->get_text, 'foo', 'text is set to foo');

ok(!$key->equals($other_key), 'now cloned key and original are not equal');
ok($key->compare($other_key) < 0, 'now cloned key and original compare less');

is($key->get_short_text, 'foo', 'short text is foo');
is($key->get_range_text, 'foo', 'range text is foo');

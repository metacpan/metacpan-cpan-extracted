#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('PickLE::Property'); }

# Blank start.
my $prop = new_ok('PickLE::Property');
ok $prop->as_string eq '', 'as_string is empty for a blank object';

# Name
is $prop->name, undef, 'name initialized as undefined';
$prop->name('Test Name');
is $prop->name, 'Test Name', 'name now set to "Test Name"';
ok $prop->as_string eq '', 'as_string is empty for an incomplete object';

# Value
is $prop->value, undef, 'value initialized as undefined';
$prop->value('Test Value');
is $prop->value, 'Test Value', 'value now set to "Test Value"';
ok $prop->as_string eq 'Test Name: Test Value', 'as_string is empty for an incomplete object';

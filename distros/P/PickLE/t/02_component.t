#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 36;

BEGIN { use_ok('PickLE::Component'); }

# Blank start.
my $comp = new_ok('PickLE::Component');
ok $comp->as_string eq '', 'as_string is empty for a blank object';

# Name
is $comp->name, '', 'name initialized as empty string';
$comp->name('Test Name');
is $comp->name, 'Test Name', 'name now set to "Test Name"';
like $comp->as_string, qr/\[ \]\s+0\s+Test Name/, 'as_string now contains name';

# Picked
is $comp->picked, 0, 'picked initialized at 0';
$comp->picked(1);
is $comp->picked, 1, 'picked now set to 1';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name/, 'as_string now checked';

# Value
is $comp->value, undef, 'value initialized as undefined';
ok $comp->has_value == 0, 'has no value';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name/, 'as_string remains unchanged';
$comp->value('2k2');
is $comp->value, '2k2', 'value now set to "2k2"';
ok $comp->has_value, 'has value';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)/, 'as_string now contains value';

# Description
is $comp->description, undef, 'description initialized as undefined';
ok $comp->has_description == 0, 'has no description';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)/, 'as_string remains unchanged';
$comp->description('A sample description');
is $comp->description, 'A sample description', 'value now set to "A sample description"';
ok $comp->has_description, 'has description';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)\s+"A sample description"/, 'as_string now contains description';

# Case
is $comp->case, undef, 'case initialized as undefined';
ok $comp->has_case == 0, 'has no case';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)\s+"A sample description"/, 'as_string remains unchanged';
$comp->case('TO-220');
is $comp->case, 'TO-220', 'case now set to "TO-220"';
ok $comp->has_case, 'has case';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)\s+"A sample description"\s+\[TO-220\]/, 'as_string now contains case';

# Reference Designators
is_deeply $comp->refdes, [], 'refdes initialized as an empty array';
is $comp->quantity, 0, 'quantity still at 0';
like $comp->as_string, qr/\[X\]\s+0\s+Test Name\s+\(2k2\)\s+"A sample description"\s+\[TO-220\]/, 'as_string remains unchanged';
$comp->add_refdes('R1');
is_deeply $comp->refdes, [ 'R1' ], 'refdes now contains "R1"';
is $comp->quantity, 1, 'quantity at 1';
like $comp->as_string, qr/\[X\]\s+1\s+Test Name\s+\(2k2\)\s+"A sample description"\s+\[TO-220\][\n\r\s]+R1/, 'as_string now contains R1 refdes';
$comp->add_refdes('R2');
is_deeply $comp->refdes, [ 'R1', 'R2' ], 'refdes now contains "R1" and "R2"';
is $comp->quantity, 2, 'quantity at 2';
like $comp->as_string, qr/\[X\]\s+2\s+Test Name\s+\(2k2\)\s+"A sample description"\s+\[TO-220\][\n\r\s]+R1\s+R2/, 'as_string now contains R2 and R2 refdes';

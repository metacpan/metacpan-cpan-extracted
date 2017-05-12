#!/usr/local/bin/perl -w

use strict;

use Test::More tests => 20;

BEGIN
{
  use_ok('Rose::HTML::Form::Field::Set');
}

my $field = 
  Rose::HTML::Form::Field::Set->new(
    label       => 'Set', 
    description => 'set',
    default     => [ qw(a b c), "one one", q(two " two), '"three"' ]);

my $vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 6 && 
   $vals->[0] eq 'a' &&
   $vals->[1] eq 'b' && 
   $vals->[2] eq 'c' &&
   $vals->[3] eq 'one one' &&
   $vals->[4] eq 'two " two' && 
   $vals->[5] eq '"three"',
   'default 1');

is($field->output_value, 'a, b, c, "one one", "two \" two", "\"three\""', 'output_value 1');

$field->input_value(q(,"foo",bar , "baz \"\nboo", 123,"",,,,));

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 5 && 
   $vals->[0] eq 'foo' &&
   $vals->[1] eq 'bar' && 
   $vals->[2] eq "baz \"\nboo" &&
   $vals->[3] eq '123' &&
   $vals->[4] eq '', 
   'default 2');

is($field->output_value, qq(foo, bar, "baz \\"\nboo", 123, ), 'output_value 2');

$field->input_value(q( , , "foo" ,  bar, "baz \"\nboo" ,123,, ""  ,,,,));

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 5 && 
   $vals->[0] eq 'foo' &&
   $vals->[1] eq 'bar' && 
   $vals->[2] eq "baz \"\nboo" &&
   $vals->[3] eq '123' &&
   $vals->[4] eq '', 
   'default 3');

is($field->output_value, qq(foo, bar, "baz \\"\nboo", 123, ), 'output_value 3');

$field->input_value([ qw(a b c), "one one", q(two " two), '"three"' ]);

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 6 && 
   $vals->[0] eq 'a' &&
   $vals->[1] eq 'b' && 
   $vals->[2] eq 'c' &&
   $vals->[3] eq 'one one' &&
   $vals->[4] eq 'two " two' && 
   $vals->[5] eq '"three"',
   'default 4');

is($field->output_value, 'a, b, c, "one one", "two \" two", "\"three\""', 'output_value 4');

$field->default(q(" hello world "));

$field->reset;

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 1 && 
   $vals->[0] eq ' hello world ',
   'default 5');

is($field->output_value, '" hello world "', 'output_value 5');

$field->input_value(q("\\" hello world \\""));

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 1 && 
   $vals->[0] eq '" hello world "',
   'default 6');

is($field->output_value, '"\" hello world \""', 'output_value 6');

$field->input_value(' ABC, DEF GHI, JKL MN ');

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 5 && 
   $vals->[0] eq 'ABC' &&
   $vals->[1] eq 'DEF' &&
   $vals->[2] eq 'GHI' &&
   $vals->[3] eq 'JKL' &&
   $vals->[4] eq 'MN',
   'default 7');

is($field->output_value, 'ABC, DEF, GHI, JKL, MN', 'output_value 7');

$field->input_value([ 'AB,C', 'D EF', 'G\H', 'I"J' ]);

$vals = $field->internal_value;

ok(ref $vals eq 'ARRAY' && 
   @$vals == 4 && 
   $vals->[0] eq 'AB,C' &&
   $vals->[1] eq 'D EF' &&
   $vals->[2] eq 'G\H' &&
   $vals->[3] eq 'I"J',
   'default 8');

is($field->output_value, '"AB,C", "D EF", "G\\\\H", "I\"J"', 'output_value 8');

$field->input_value(qq("""));

ok(!$field->validate, 'validate 1');
is($field->error, 'Could not parse input: parse error at [..."]', 'error 1');

SET_FIELD_BUG:
{
  package TestForm;
  use base 'Rose::HTML::Form';
  sub build_form { shift->add_fields(testfld => { type  => 'set' }); }

  package main;
  my $f = TestForm->new;
  eval { $f->field('testfld')->xhtml_hidden_field };
  ok(!$@, 'empty set');
}

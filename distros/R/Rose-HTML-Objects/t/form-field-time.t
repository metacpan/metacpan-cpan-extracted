#!/usr/bin/perl -w

use strict;

use Test::More tests => 38;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Time');
}

my $field = Rose::HTML::Form::Field::Time->new(
  label       => 'Time', 
  description => 'Some Time',
  name        => 'time',
  value       => ' 12:34:56p.m.',
  default     => '8am');

ok(ref $field eq 'Rose::HTML::Form::Field::Time', 'new()');

is($field->html_field, '<input name="time" size="13" type="text" value="12:34:56 PM">', 'html_field() 1');
is($field->xhtml_field, '<input name="time" size="13" type="text" value="12:34:56 PM" />', 'xhtml_field() 1');

is($field->input_value, ' 12:34:56p.m.', 'input_value() 1');
is($field->input_value_filtered, '12:34:56p.m.', 'input_value_filtered() 1');
is($field->internal_value, '12:34:56 PM', 'internal_value() 1');
is($field->output_value, '12:34:56 PM', 'output_value() 1');

$field->clear;

is($field->html_field, '<input name="time" size="13" type="text" value="">', 'html_field() 2');
is($field->xhtml_field, '<input name="time" size="13" type="text" value="" />', 'xhtml_field() 2');

is($field->input_value, undef, 'input_value() 2');
is($field->input_value_filtered, undef, 'input_value_filtered() 2');
is($field->internal_value, undef, 'internal_value() 2');
is($field->output_value, undef, 'output_value() 2');

$field->reset;

is($field->html_field, '<input name="time" size="13" type="text" value="08:00:00 AM">', 'html_field() 3');
is($field->xhtml_field, '<input name="time" size="13" type="text" value="08:00:00 AM" />', 'xhtml_field() 3');

is($field->input_value, '8am', 'input_value() 3');
is($field->input_value_filtered, '8am', 'input_value_filtered() 3');
is($field->internal_value, '08:00:00 AM', 'internal_value() 3');
is($field->output_value, '08:00:00 AM', 'output_value() 3');

is($field->validate, 1, 'validate() 1');

$field->input_value('foo');

is($field->input_value, 'foo', 'input_value() 4');
is($field->input_value_filtered, 'foo', 'input_value_filtered() 4');
is($field->internal_value, 'foo', 'internal_value() 4');
is($field->output_value, 'foo', 'output_value() 4');

is($field->validate, 0, 'validate() 2');

$field->output_filter(sub { uc });

is($field->input_value, 'foo', 'input_value() 5');
is($field->input_value_filtered, 'foo', 'input_value_filtered() 5');
is($field->internal_value, 'foo', 'internal_value() 5');
is($field->output_value, 'FOO', 'output_value() 5');

$field->output_filter(sub { lc });
$field->input_filter(sub { s/^-//; $_ });

$field->input_value('-5:01am');

is($field->validate, 1, 'validate() 3');

is($field->input_value, '-5:01am', 'input_value() 6');
is($field->input_value_filtered, '5:01am', 'input_value_filtered() 6');
is($field->internal_value, '05:01:00 AM', 'internal_value() 6');
is($field->output_value, '05:01:00 am', 'output_value() 6');

$field->input_value('-13:01am');

is($field->validate, 0, 'validate() 4');

$field = Rose::HTML::Form::Field::Time->new(name => 'new');
ok($field->validate, 'validate() empty 1');
$field->input_value('');
ok($field->validate, 'validate() empty 2');

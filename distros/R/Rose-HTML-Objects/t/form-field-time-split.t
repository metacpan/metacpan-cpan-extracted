#!/usr/bin/perl -w

use strict;

use Test::More tests => 20;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Time::Split::HourMinuteSecond');
}

my $field = Rose::HTML::Form::Field::Time::Split::HourMinuteSecond->new(
  label       => 'Time', 
  description => 'Some Time',
  name        => 'time',
  value       => ' 12:34:56p.m.',
  default     => '8am');

ok(ref $field eq 'Rose::HTML::Form::Field::Time::Split::HourMinuteSecond', 'new()');

is($field->html_field, 
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="time.hour" size="2" type="text" value="12">:' .
  '<input class="minute" maxlength="2" name="time.minute" size="2" type="text" value="34">:' .
  '<input class="second" maxlength="2" name="time.second" size="2" type="text" value="56">' .
  qq(<select class="ampm" name="time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected value="PM">PM</option>\n) .
  '</select></span>',
  'html_field() 1');

is($field->xhtml_field, 
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="time.hour" size="2" type="text" value="12" />:' .
  '<input class="minute" maxlength="2" name="time.minute" size="2" type="text" value="34" />:' .
  '<input class="second" maxlength="2" name="time.second" size="2" type="text" value="56" />' .
  qq(<select class="ampm" name="time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected="selected" value="PM">PM</option>\n) .
  '</select></span>',
  'xhtml_field() 1');

$field->clear;

is($field->internal_value, undef, 'internal_value() 1');

is($field->html_field, 
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="time.hour" size="2" type="text" value="">:' .
  '<input class="minute" maxlength="2" name="time.minute" size="2" type="text" value="">:' .
  '<input class="second" maxlength="2" name="time.second" size="2" type="text" value="">' .
  qq(<select class="ampm" name="time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option value="PM">PM</option>\n) .
  '</select></span>',
  'html_field() 2');

$field->reset;

is($field->internal_value, '08:00:00 AM', 'internal_value() 2');

is($field->html_field, 
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="time.hour" size="2" type="text" value="08">:' .
  '<input class="minute" maxlength="2" name="time.minute" size="2" type="text" value="00">:' .
  '<input class="second" maxlength="2" name="time.second" size="2" type="text" value="00">' .
  qq(<select class="ampm" name="time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option selected value="AM">AM</option>\n) .
  qq(<option value="PM">PM</option>\n) .
  '</select></span>',
  'html_field() 3');

$field->input_value('foo');
is($field->error, undef, 'error() 1');

is($field->validate, 0, 'validate() 1');
ok($field->error =~ /\S/, 'error() 2');

is($field->internal_value, 'foo', 'internal_value() 3');
is($field->input_value, 'foo', 'input_value() 1');
is($field->output_value, 'foo', 'output_value() 1');

# Test subfield population

$field->clear;

$field->field('minute')->input_value(34);

ok(!defined $field->internal_value, 'minute only');

$field->field('second')->input_value(56);

ok(!defined $field->internal_value, 'minute and second');

$field->reset;

is($field->internal_value, '08:00:00 AM', 'partial reset()');

$field->clear;

$field->field('hour')->input_value(12);

ok(!defined $field->internal_value, 'hour only');

$field->field('ampm')->input_value('PM');

is($field->internal_value, '12:00:00 PM', 'hour and am/pm');

$field->clear;
$field->field('ampm')->input_value('PM');
$field->field('hour')->input_value(' ');

ok(!defined $field->internal_value, 'invalid hour');



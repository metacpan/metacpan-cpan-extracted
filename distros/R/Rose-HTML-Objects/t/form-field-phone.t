#!/usr/bin/perl -w

use strict;

use Test::More tests => 23;

use Rose::HTML::Object::Errors qw(:phone);

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::PhoneNumber::US');
  use_ok('Rose::HTML::Form::Field::PhoneNumber::US::Split');
}

#
# Rose::HTML::Form::Field::PhoneNumber::US
#

my $field = Rose::HTML::Form::Field::PhoneNumber::US->new(
  name        => 'phone',  
  value       => '555-555-5555',
  default     => '555-123-1234');

ok(ref $field eq 'Rose::HTML::Form::Field::PhoneNumber::US', 'US new()');

is($field->internal_value, '555-555-5555', 'US internal_value() 1');

$field->clear;

is($field->html_field, '<input maxlength="14" name="phone" size="15" type="text" value="">', 'US html_field() 1');
is($field->xhtml_field, '<input maxlength="14" name="phone" size="15" type="text" value="" />', 'US xhtml_field() 1');

$field->reset;

is($field->internal_value, '555-123-1234', 'US reset()');

$field->input_value(' ( 123) 456 7890 ');

is($field->internal_value, '123-456-7890', 'US internal_value() 2');

#
# Rose::HTML::Form::Field::PhoneNumber::US::Split
#

$field = Rose::HTML::Form::Field::PhoneNumber::US::Split->new(
  name        => 'phone',  
  value       => '555-456-5555',
  default     => '123-321-1234');

ok(ref $field eq 'Rose::HTML::Form::Field::PhoneNumber::US::Split', 'US::Split new()');

is($field->html_field, 
  '<span class="phone">' .
  '<input class="area-code" maxlength="3" name="phone.area_code" size="3" type="text" value="555">-' .
  '<input class="exchange" maxlength="3" name="phone.exchange" size="3" type="text" value="456">-' .
  '<input class="number" maxlength="4" name="phone.number" size="4" type="text" value="5555"></span>',
  'US::Split  html_field() 1');

is($field->xhtml_field,
  '<span class="phone">' .
  '<input class="area-code" maxlength="3" name="phone.area_code" size="3" type="text" value="555" />-' .
  '<input class="exchange" maxlength="3" name="phone.exchange" size="3" type="text" value="456" />-' .
  '<input class="number" maxlength="4" name="phone.number" size="4" type="text" value="5555" /></span>',
  'US::Split xhtml_field() 1');

is($field->internal_value, '555-456-5555', 'US::Split internal_value() 1');

$field->clear;

is($field->html_field, 
  '<span class="phone">' .
  '<input class="area-code" maxlength="3" name="phone.area_code" size="3" type="text" value="">-' .
  '<input class="exchange" maxlength="3" name="phone.exchange" size="3" type="text" value="">-' .
  '<input class="number" maxlength="4" name="phone.number" size="4" type="text" value=""></span>',
  'US::Split html_field() 2');

$field->reset;

is($field->internal_value, '123-321-1234', 'US::Split reset()');

$field->input_value(' ( 123) 456 7890 ');

is($field->internal_value, '123-456-7890', 'US::Split internal_value() 2');

# Test subfield population

$field->clear;

$field->field('area_code')->input_value(555);

ok(!defined $field->internal_value, 'US::Split area code only');

$field->field('exchange')->input_value(123);

ok(!defined $field->internal_value, 'US::Split area code and exchange');

$field->reset;

is($field->internal_value, '123-321-1234', 'US::Split partial reset()');

$field->clear;

$field->field('exchange')->input_value(123);

ok(!defined $field->internal_value, 'US::Split exchange only');

$field->field('area_code')->input_value(555);
$field->field('number')->input_value(4567);

is($field->internal_value, '555-123-4567', 'US::Split area code, exchange, and number');

$field->input_value(123);
$field->validate;
ok($field->has_error, 'has_error 1');
is($field->error_id, PHONE_INVALID, 'error_id 1');
is($field->error, 'Phone number must be 10 digits, including area code.', 'error 1');

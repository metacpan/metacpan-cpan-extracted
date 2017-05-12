#!/usr/local/bin/perl -w

use strict;

use Test::More tests => 17;

SKIP:
{
  eval { require Email::Valid };

  if($@)
  {
    skip("all tests: could not load Email::Valid", 17);
  }

  use_ok('Rose::HTML::Form::Field::Email');

  my $field = Rose::HTML::Form::Field::Email->new(
    label       => 'Email', 
    description => 'Your email',
    name        => 'email',  
    value       => 'foo@bar.com',
    default     => 'none@none.com',
    maxlength   => 50);

  ok(ref $field eq 'Rose::HTML::Form::Field::Email', 'new()');

  is($field->html_field, '<input maxlength="50" name="email" size="15" type="text" value="foo@bar.com">', 'html_field() 1');
  is($field->xhtml_field, '<input maxlength="50" name="email" size="15" type="text" value="foo@bar.com" />', 'xhtml_field() 1');

  $field->clear;

  is($field->internal_value, undef, 'clear()');

  is($field->html_field, '<input maxlength="50" name="email" size="15" type="text" value="">', 'html_field() 2');
  is($field->xhtml_field, '<input maxlength="50" name="email" size="15" type="text" value="" />', 'xhtml_field() 2');

  $field->reset;

  is($field->internal_value, 'none@none.com', 'reset()');

  is($field->html_field, '<input maxlength="50" name="email" size="15" type="text" value="none@none.com">', 'html_field() 3');
  is($field->xhtml_field, '<input maxlength="50" name="email" size="15" type="text" value="none@none.com" />', 'xhtml_field() 3');

  $field->input_value('foo@bar.com');

  $field->class('foo');
  $field->id('bar');
  $field->style('baz');

  is($field->html_field, '<input class="foo" id="bar" maxlength="50" name="email" size="15" style="baz" type="text" value="foo@bar.com">', 'html_field() 4');
  is($field->xhtml_field, '<input class="foo" id="bar" maxlength="50" name="email" size="15" style="baz" type="text" value="foo@bar.com" />', 'xhtml_field() 4');

  $field->value('bad');  
  ok(!$field->validate, 'validate() 1');

  $field->value('bad@bad');  
  ok(!$field->validate, 'validate() 2');

  $field->value('bad@@bad.com');  
  ok(!$field->validate, 'validate() 3');

  $field->value(' good@good.com ');  
  ok($field->validate, 'validate() 4');

  ok(!$field->error, 'error()');
}

#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::File');
}

my $field = Rose::HTML::Form::Field::File->new(
  label       => 'Name', 
  description => 'Your name',
  name        => 'name',  
  value       => 'John',
  default     => 'Anonymous',
  maxlength   => 20);

ok(ref $field && $field->isa('Rose::HTML::Form::Field::File'), 'new()');

is($field->html_field, '<input maxlength="20" name="name" size="15" type="file" value="John">', 'html_field() 1');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="file" value="John" />', 'xhtml_field() 1');

$field->clear;

is($field->output_value, undef, 'clear()');

is($field->html_field, '<input maxlength="20" name="name" size="15" type="file" value="">', 'html_field() 2');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="file" value="" />', 'xhtml_field() 2');

$field->reset;

is($field->output_value, 'Anonymous', 'reset()');

is($field->html_field, '<input maxlength="20" name="name" size="15" type="file" value="Anonymous">', 'html_field() 3');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="file" value="Anonymous" />', 'xhtml_field() 3');

$field->input_value('John');

$field->class('foo');
$field->id('bar');
$field->style('baz');

is($field->html_field, '<input class="foo" id="bar" maxlength="20" name="name" size="15" style="baz" type="file" value="John">', 'html_field() 4');
is($field->xhtml_field, '<input class="foo" id="bar" maxlength="20" name="name" size="15" style="baz" type="file" value="John" />', 'xhtml_field() 4');

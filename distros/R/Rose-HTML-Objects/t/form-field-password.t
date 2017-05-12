#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Password');
}

my $field = Rose::HTML::Form::Field::Password->new(
  name        => 'name',  
  value       => 'John',
  default     => 'Anonymous',
  maxlength   => 20);

ok(ref $field eq 'Rose::HTML::Form::Field::Password', 'new()');

is($field->html_field, '<input maxlength="20" name="name" size="15" type="password" value="John">', 'html_field() 1');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="password" value="John" />', 'xhtml_field() 1');

$field->clear;

is($field->html_field, '<input maxlength="20" name="name" size="15" type="password" value="">', 'html_field() 2');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="password" value="" />', 'xhtml_field() 2');

$field->reset;

is($field->html_field, '<input maxlength="20" name="name" size="15" type="password" value="Anonymous">', 'html_field() 3');
is($field->xhtml_field, '<input maxlength="20" name="name" size="15" type="password" value="Anonymous" />', 'xhtml_field() 3');

$field->value('John');

$field->class('foo');
$field->id('bar');
$field->style('baz');

is($field->html_field, '<input class="foo" id="bar" maxlength="20" name="name" size="15" style="baz" type="password" value="John">', 'html_field() 4');
is($field->xhtml_field, '<input class="foo" id="bar" maxlength="20" name="name" size="15" style="baz" type="password" value="John" />', 'xhtml_field() 4');

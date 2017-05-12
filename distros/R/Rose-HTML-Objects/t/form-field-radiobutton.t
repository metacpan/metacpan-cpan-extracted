#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::RadioButton');
}

my $field = Rose::HTML::Form::Field::RadioButton->new(
  label       => 'Run tests', 
  description => 'Run diagnostic tests',
  name        => 'tests',  
  value       => 'yes');

ok(ref $field && $field->isa('Rose::HTML::Form::Field::RadioButton'), 'new()');

is($field->html_field, '<input name="tests" type="radio" value="yes"> <label>Run tests</label>', 'html_field() 1');
is($field->xhtml_field, '<input name="tests" type="radio" value="yes" /> <label>Run tests</label>', 'xhtml_field() 1');

$field->value('on');

is($field->html_field, '<input name="tests" type="radio" value="on"> <label>Run tests</label>', 'html_field() 2');
is($field->xhtml_field, '<input name="tests" type="radio" value="on" /> <label>Run tests</label>', 'xhtml_field() 2');

$field->default(1);

is($field->html_field, '<input checked name="tests" type="radio" value="on"> <label>Run tests</label>', 'html_field() 3');
is($field->xhtml_field, '<input checked="checked" name="tests" type="radio" value="on" /> <label>Run tests</label>', 'xhtml_field() 3');

$field->class('foo');
$field->id('bar');
$field->style('baz');

$field->default(0);
$field->value('yep');

is($field->html_field, '<input class="foo" id="bar" name="tests" style="baz" type="radio" value="yep"> <label for="bar">Run tests</label>', 'html_field() 4');
is($field->xhtml_field, '<input class="foo" id="bar" name="tests" style="baz" type="radio" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 4');

ok(!$field->checked, 'checked()');

$field->checked(1);

is($field->html_field, '<input checked class="foo" id="bar" name="tests" style="baz" type="radio" value="yep"> <label for="bar">Run tests</label>', 'html_field() 5');
is($field->xhtml_field, '<input checked="checked" class="foo" id="bar" name="tests" style="baz" type="radio" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 5');

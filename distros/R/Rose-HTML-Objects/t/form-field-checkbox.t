#!/usr/bin/perl -w

use strict;

use Test::More tests => 32;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Checkbox');
}

my $field = Rose::HTML::Form::Field::Checkbox->new(
  label       => 'Run tests', 
  description => 'Run diagnostic tests',
  name        => 'tests',  
  value       => 'yes');

ok(ref $field && $field->isa('Rose::HTML::Form::Field::Checkbox'), 'new()');

is($field->html_field, '<input name="tests" type="checkbox" value="yes"> <label>Run tests</label>', 'html_field() 1');
is($field->xhtml_field, '<input name="tests" type="checkbox" value="yes" /> <label>Run tests</label>', 'xhtml_field() 1');

$field->value('on');

is($field->html_field, '<input name="tests" type="checkbox" value="on"> <label>Run tests</label>', 'html_field() 2');
is($field->xhtml_field, '<input name="tests" type="checkbox" value="on" /> <label>Run tests</label>', 'xhtml_field() 2');

is($field->value_label, undef, 'value_label() 1');

$field->default(1);

is($field->html_field, '<input checked name="tests" type="checkbox" value="on"> <label>Run tests</label>', 'html_field() 3');
is($field->xhtml_field, '<input checked="checked" name="tests" type="checkbox" value="on" /> <label>Run tests</label>', 'xhtml_field() 3');

is($field->value_label, 'Run tests', 'value_label() 2');

$field->class('foo');
$field->id('bar');
$field->style('baz');

$field->default(0);
$field->value('yep');

is($field->html_field, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep"> <label for="bar">Run tests</label>', 'html_field() 4');
is($field->xhtml_field, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 4');

is($field->checked, 0, 'checked() 1');

is($field->checked('abc'), 1, 'checked() 2');

is($field->html_field, '<input checked class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep"> <label for="bar">Run tests</label>', 'html_field() 5');
is($field->xhtml_field, '<input checked="checked" class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 5');

is($field->html_checkbox, '<input checked class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep">', 'html_checkbox() 1');
is($field->xhtml_checkbox, '<input checked="checked" class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" />', 'xhtml_checkbox() 1');

$field->default(1);
$field->clear;

is($field->html_field, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep"> <label for="bar">Run tests</label>', 'html_field() 6');
is($field->xhtml_field, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 6');

is($field->html_checkbox, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep">', 'html_checkbox() 2');
is($field->xhtml_checkbox, '<input class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" />', 'xhtml_checkbox() 2');

$field->reset;

is($field->html_field, '<input checked class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep"> <label for="bar">Run tests</label>', 'html_field() 7');
is($field->xhtml_field, '<input checked="checked" class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" /> <label for="bar">Run tests</label>', 'xhtml_field() 7');

is($field->html_checkbox, '<input checked class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep">', 'html_checkbox() 3');
is($field->xhtml_checkbox, '<input checked="checked" class="foo" id="bar" name="tests" style="baz" type="checkbox" value="yep" />', 'xhtml_checkbox() 3');

is($field->html_label, '<label for="bar">Run tests</label>','html label before add class');
is($field->xhtml_label, '<label for="bar">Run tests</label>','xhtml label before add class');

$field->label_object->add_class(q{test_class});

is($field->html_label, '<label class="test_class" for="bar">Run tests</label>', 'html label after add class');
is($field->xhtml_label, '<label class="test_class" for="bar">Run tests</label>', 'xhtml label after add class');

$field->label_object->delete_class(q{test_class});

is($field->html_label, '<label class="" for="bar">Run tests</label>', 'html label after delete class');
is($field->xhtml_label, '<label class="" for="bar">Run tests</label>', 'xhtml label after delete class');

#!/usr/bin/perl -w

use strict;

use Test::More tests => 27;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::TextArea');
}

use Rose::HTML::Object::Errors qw(:string);

my $field = Rose::HTML::Form::Field::TextArea->new(
  name    => 'name',  
  value   => 'John & Tina',
  default => 'Anonymous');

ok(ref $field eq 'Rose::HTML::Form::Field::TextArea', 'new()');

is($field->html_field, 
   '<textarea cols="50" name="name" rows="6">John &amp; Tina</textarea>',
   'html_field() 1');

is($field->xhtml_field,
   '<textarea cols="50" name="name" rows="6">John &amp; Tina</textarea>',
   'xhtml_field() 1');

$field->input_value(' John & Tina ');

is($field->html_field,
   '<textarea cols="50" name="name" rows="6">John &amp; Tina</textarea>',
   'html_field() 2');

is($field->xhtml_field,
   '<textarea cols="50" name="name" rows="6">John &amp; Tina</textarea>',
   'xhtml_field() 2');

$field->clear;

is($field->html_field, 
   '<textarea cols="50" name="name" rows="6"></textarea>',
   'html_field() 3');

is($field->xhtml_field,
   '<textarea cols="50" name="name" rows="6"></textarea>',
   'xhtml_field() 3');

$field->reset;

is($field->html_field, 
   '<textarea cols="50" name="name" rows="6">Anonymous</textarea>',
   'html_field() 4');

is($field->xhtml_field,
   '<textarea cols="50" name="name" rows="6">Anonymous</textarea>',
   'xhtml_field() 4');

$field->contents('John2');

$field->class('foo');
$field->id('bar');
$field->style('baz');

$field->rows(10);
$field->cols(80);
$field->disabled('abc');

is($field->size, '80x10', 'size() 1');

is($field->html_field, 
   '<textarea class="foo" cols="80" disabled id="bar" name="name" rows="10" style="baz">John2</textarea>',
   'html_field() 5');

$field->input_value('John');

is($field->xhtml_field,
   '<textarea class="foo" cols="80" disabled="disabled" id="bar" name="name" rows="10" style="baz">John</textarea>',
   'xhtml_field() 5');

is($field->size, '80x10', 'size() 1');

eval { $field->size(90) };
ok($@, 'invalid size');

is($field->size('50x3'), '50x3', 'size() 1');

is($field->html_field, 
   '<textarea class="foo" cols="50" disabled id="bar" name="name" rows="3" style="baz">John</textarea>',
   'html_field() 6');

is($field->xhtml_field,
   '<textarea class="foo" cols="50" disabled="disabled" id="bar" name="name" rows="3" style="baz">John</textarea>',
   'xhtml_field() 6');

$field->required(1);
$field->default(undef);
$field->input_value(undef);

ok(!$field->validate, 'validate 1');
ok($field->error, 'error 1');

$field->label('Stuff');

is($field->html_label, '<label class="required error" for="bar">Stuff</label>', 'html_label() 1');
is($field->xhtml_label, '<label class="required error" for="bar">Stuff</label>', 'xhtml_label() 1');

is($field->xhtml,
   qq(<textarea class="foo error" cols="50" disabled="disabled" id="bar" name="name" rows="3" style="baz"></textarea><br />\n) . 
   qq(<span class="error">This is a required field.</span>),
   'xhtml() 1');

$field->clear;
$field->maxlength(10);

$field->input_value('12345678901');

ok(!$field->validate, 'maxlength 1');
is($field->error_id, STRING_OVERFLOW, 'maxlength 2');

$field = Rose::HTML::Form::Field::TextArea->new(name => 'foo', label => 'Foo', required => 1);

$field->validate;

is($field->error, 'Foo is a required field.', 'error en');

$field->locale('de');

is($field->error, 'Foo ist ein Pflichtfeld.', 'error de');

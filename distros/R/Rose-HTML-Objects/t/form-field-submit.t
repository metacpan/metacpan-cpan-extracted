#!/usr/bin/perl -w

use strict;

use Test::More tests => 20;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Submit');
}

my $field = Rose::HTML::Form::Field::Submit->new(
  name  => 'search',  
  value => 'Search');

ok(ref $field eq 'Rose::HTML::Form::Field::Submit', 'new()');

is($field->html_field, '<input name="search" type="submit" value="Search">', 'html_field() 1');
is($field->xhtml_field, '<input name="search" type="submit" value="Search" />', 'xhtml_field() 1');

$field->src('foo.gif');
$field->alt('Foo');

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 2');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 2');

is($field->image_html(src => 'bar.gif', alt => 'bar'), 
     '<input alt="bar" name="search" src="bar.gif" type="image" value="Search">', 'image_html()');

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 3');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 3');

is($field->image_xhtml(src => 'xbar.gif', alt => 'xbar'), 
     '<input alt="xbar" name="search" src="xbar.gif" type="image" value="Search" />', 'image_xhtml()');

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 4');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 4');

$field->input_value('abc');
is($field->internal_value, undef, 'internal_value() 1');

$field->input_value('Search');
is($field->internal_value, 'Search', 'internal_value() 2');

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 5');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 5');

$field->clear;

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 6');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 6');

$field->reset;

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search">', 'html_field() 7');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="submit" value="Search" />', 'xhtml_field() 7');

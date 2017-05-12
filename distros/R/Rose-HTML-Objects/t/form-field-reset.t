#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Reset');
}

my $field = Rose::HTML::Form::Field::Reset->new(
  name  => 'search',  
  value => 'Search');

ok(ref $field eq 'Rose::HTML::Form::Field::Reset', 'new()');

is($field->html_field, '<input name="search" type="reset" value="Search">', 'html_field() 1');
is($field->xhtml_field, '<input name="search" type="reset" value="Search" />', 'xhtml_field() 1');

$field->src('foo.gif');
$field->alt('Foo');

is($field->html_field, '<input alt="Foo" name="search" src="foo.gif" type="reset" value="Search">', 'html_field() 2');
is($field->xhtml_field, '<input alt="Foo" name="search" src="foo.gif" type="reset" value="Search" />', 'xhtml_field() 2');

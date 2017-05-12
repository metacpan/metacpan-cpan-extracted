#!/usr/bin/perl -w

use strict;

use Test::More tests => 89;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field');
  use_ok('Rose::Object');
}

my $field = Rose::HTML::Form::Field->new(
  label       => 'Name', 
  description => 'Your name',
  default     => 'Anonymous 1');
ok(ref $field eq 'Rose::HTML::Form::Field', 'new()');

eval { $field->add_field($field) };
ok($@, 'recursive field nesting failure 1');

eval { $field->add_field(foo => $field) };
ok($@, 'recursive field nesting failure 2');

is($field->input_value('John'), 'John', 'input_value()');
is($field->internal_value, 'John', 'internal_value() 1');

$field->input_value(undef);
is($field->internal_value, 'Anonymous 1', 'default()');

$field->default_value('Anonymous');
is($field->internal_value, 'Anonymous', 'default_value()');

ok($field->validate, 'validate() true');

$field->default(undef);
$field->required(1);

ok(!$field->validate, 'validate() false');

$field->input_value(' a ');
is($field->internal_value, 'a' , 'trim_spaces() true');

$field->trim_spaces(0);
$field->input_value(' a ');
is($field->internal_value, ' a ', 'trim_spaces() false');

$field->trim_spaces(1);
$field->input_filter(sub { uc });
$field->input_value(' hello ');

is($field->internal_value, 'HELLO', 'input_filter() alone');

$field->input_filter(undef);

$field->output_filter(sub { ucfirst });
$field->input_value(' hello ');
is($field->output_value, 'Hello', 'output_filter() alone');

$field->input_filter(sub { uc });
$field->output_filter(sub { lcfirst });
$field->input_value(' hello ');

is($field->internal_value, 'HELLO', 'input_filter() combined');
is($field->output_value, 'hELLO', 'output_filter() combined');

$field->filter(sub 
{
  my($self, $value) = @_; 

  no warnings 'uninitialized';
  if($self->trim_spaces)
  {
    $value = ucfirst($value);
  }
  else
  {
    $value = uc $value;
  }

  return $value;
});

$field->input_value(' hello ');
is($field->internal_value, 'Hello', 'filter() 1');
is($field->output_value, 'Hello', 'filter() 2');

$field->trim_spaces(0);
$field->input_value(' hello ');
is($field->internal_value, ' HELLO ', 'filter() 3');
is($field->internal_value, ' HELLO ', 'filter() 4');

$field->clear();
is($field->internal_value, undef, 'clear()');

$field->trim_spaces(1);
$field->input_value(' John ');
is($field->input_value, ' John ', 'input_value()');

ok($field->validate, 'validate() again');

is($field->html_field, '<></>', 'html_field() 1');
is($field->xhtml_field, '<></>', 'xhtml_field() 1');

is($field->html, '<></>', 'html() 1');
is($field->xhtml, '<></>', 'xhtml() 1');

$field->input_value(undef);
$field->validate;

is($field->html_field, '<></>', 'html_field() 2');
is($field->xhtml_field, '<></>', 'xhtml_field() 2');

is($field->html, qq(<></><br>\n<span class="error">Name is a required field.</span>), 'html() 2');
is($field->xhtml, qq(<></><br />\n<span class="error">Name is a required field.</span>), 'xhtml() 2');

$field->label('Name> ');

is($field->html_label, '<label class="required error">Name&gt; </label>', 'html_label() 1');
is($field->xhtml_label, '<label class="required error">Name&gt; </label>', 'xhtml_label() 1');
$field->escape_html(0);

is($field->html_label, '<label class="required error">Name> </label>', 'html_label() 2');
is($field->xhtml_label, '<label class="required error">Name> </label>', 'xhtml_label() 2');

$field->validator(sub { 0 });

is($field->validate, 0, 'validator()');

$field->name('name');
$field->value('John >');

my $hidden = $field->hidden_field;
ok(ref $hidden eq 'Rose::HTML::Form::Field::Hidden', 'hidden_field()');

$hidden = $field->hidden_fields;
ok(ref $hidden eq 'Rose::HTML::Form::Field::Hidden', 'hidden_fields() 1');

my @hidden = $field->hidden_fields;
ok(@hidden == 1 && ref $hidden[0] && $hidden[0]->isa('Rose::HTML::Form::Field::Hidden'), 'hidden_fields() 2');

is($hidden->html_field, '<input name="name" type="hidden" value="John &gt;">', 'hidden_field() html');
is($hidden->xhtml_field, '<input name="name" type="hidden" value="John &gt;" />', 'hidden_field() xml');
is($field->html_hidden_field, '<input name="name" type="hidden" value="John &gt;">', 'html_hidden_field()');
is($field->xhtml_hidden_field, '<input name="name" type="hidden" value="John &gt;" />', 'xhtml_hidden_field()');

$field->id('myid');
$field->class('myclass');
$hidden = $field->hidden_field;

is($hidden->html_field, '<input class="myclass" id="myid" name="name" type="hidden" value="John &gt;">', 'hidden_field() html extra');
is($hidden->xhtml_field, '<input class="myclass" id="myid" name="name" type="hidden" value="John &gt;" />', 'hidden_field() xml extra');
is($field->html_hidden_field, '<input class="myclass" id="myid" name="name" type="hidden" value="John &gt;">', 'html_hidden_field() extra');
is($field->xhtml_hidden_field, '<input class="myclass" id="myid" name="name" type="hidden" value="John &gt;" />', 'xhtml_hidden_field() extra');

$field->class('foo');
is($field->class, 'foo', 'class()');

$field->id('bar');
is($field->id, 'bar', 'id()');

$field->escape_html(1);
is($field->html_label, '<label class="required" for="bar">Name&gt; </label>', 'html_label() 3');
is($field->xhtml_label, '<label class="required" for="bar">Name&gt; </label>', 'xhtml_label() 3');
$field->escape_html(0);

is($field->html_label, '<label class="required" for="bar">Name> </label>', 'html_label() 4');
is($field->xhtml_label, '<label class="required" for="bar">Name> </label>', 'xhtml_label() 5');

$field->style('baz');
is($field->style, 'baz', 'style()');

foreach my $attr ($field->valid_html_attrs)
{
  is($field->html_attr_is_valid($attr), 1, "valid_html_attrs() $attr");
}

$field->input_filter(sub
{
  my($self, $value) = @_;

  if($value =~ /\S/)
  {
    return Person->new(name => $value);
  }

  return $value;
});

$field->input_value('John');

my $p = $field->internal_value;

is(ref $p, 'Person', 'internal_value() 2');
is($p->name, 'John', 'internal_value() 3');

$field->output_filter(sub
{
  my($self, $value) = @_;

  return $value->name  if(ref $value eq 'Person');
  return $value;
});

is($field->output_value, 'John', 'output_value() 1');

$field->reset;

$field->default_value('Anonymous');

is($field->input_value, 'Anonymous', 'reset() 1');
is($field->internal_value->name, 'Anonymous', 'reset() 2');
is($field->output_value, 'Anonymous', 'reset() 3');

# $field->name('name');
# is($field->field_name, 'name', 'field_name() 1');
# 
# $field->field_name('name_field');
# #is($field->field_name, 'name_field', 'field_name() 2');
# #is($field->name, 'name', 'name() 1');
# 
# $field->name(undef);
# is($field->name, 'name_field', 'name() 2');
# 
# $field->field_name(undef);
# is($field->name, undef, 'name() 3');
# is($field->field_name, undef, 'field_name() 3');
# 
# $field->name('name');
# is($field->field_name, 'name', 'field_name() 4');
# is($field->name, 'name', 'name() 4');
# 
# $field->field_name(undef);
# $field->name(undef);
# is($field->name, undef, 'name() 5');
# is($field->field_name, undef, 'field_name() 5');

$field->input_filter(sub { uc });

$field->input_value(' foo ');

is($field->input_value_filtered, 'FOO', 'input_value_filtered()');

$field->error('foo');

is($field->error, 'foo', 'error() 1');

$field->input_value('bar');

ok(!$field->error, 'error() 2');

# 0.603: HTML label class="..." bug fix
$field = Rose::HTML::Form::Field->new(label => 'Test');
$field->error('foo');
$field->label_object;
$field->reset;
ok($field->xhtml_label !~ /error/, 'label class cleared correctly');

BEGIN
{
  package Person;

  use strict;

  @Person::ISA = qw(Rose::Object);

  use Rose::Object::MakeMethods::Generic
  (
    'scalar' => [ qw(name age) ],
  );
}

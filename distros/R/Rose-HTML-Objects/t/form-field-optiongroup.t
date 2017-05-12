#!/usr/bin/perl -w

use strict;

use Test::More tests => 62;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::OptionGroup');
}

my $field = Rose::HTML::Form::Field::OptionGroup->new(name  => 'fruits', 
                                                      label => 'Group 1');

ok(ref $field eq 'Rose::HTML::Form::Field::OptionGroup', 'new()');

is(scalar @{ $field->children }, 0, 'children scalar 1');
is(scalar(() = $field->children), 0, 'children list 1');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

is(scalar @{ $field->children }, 3, 'children scalar 2');
is(scalar(() = $field->children), 3, 'children list 2');

$field->option('apple')->short_label('1.0');
$field->option('orange')->short_label('2.0');
$field->option('grape')->short_label('3.0');

is($field->html_field, 
  qq(<optgroup label="Group 1">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'html_field() 1');

is($field->label('Fruits'), 'Fruits', 'label()');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'html_field() 2');

$field->option('apple')->label('<b>Apple</b>');
$field->escape_html(0);

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'escape_html() 1');

$field->escape_html(1);

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'escape_html() 2');

is($field->xhtml_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'xhtml_field() 1');

$field->error('Whatever');

is($field->html,
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'html() 1');

is($field->xhtml, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'xhtml() 1');

$field->option('apple')->label('Apple');

$field->default('apple');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" selected value="apple">Apple</option>\n) .
  qq(<option label="2.0" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'default()');

is($field->value_label, 'Apple', 'value_label()');

$field->input_value('orange');

is($field->xhtml_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option label="2.0" selected="selected" value="orange">Orange</option>\n) .
  qq(<option label="3.0" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'value() 1');

$field->error(undef);

$field->option('apple')->delete_html_attr('label');
$field->option('orange')->delete_html_attr('label');
$field->option('grape')->delete_html_attr('label');

$field->multiple(1);

$field->add_value('apple');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'add_value() 1');

is(join(',', $field->internal_value), 'apple,orange', 'internal_value() 1');
is(join(',', @{$field->output_value}), 'apple,orange', 'output_value() 1');
is(join(',', @{$field->values}), 'apple,orange', 'values() 1');

$field->input_value(undef);

$field->add_values('orange', 'grape');

is($field->xhtml_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected="selected" value="orange">Orange</option>\n) .
  qq(<option selected="selected" value="grape">Grape</option>\n) .
  qq(</optgroup>),
  'add_values() 1');

is(join(',', $field->internal_value), 'grape,orange', 'internal_value() 2');
is(join(',', @{$field->output_value}), 'grape,orange', 'output_value() 2');
is(join(',', @{$field->values}), 'grape,orange', 'values() 2');

ok($field->is_selected('orange'), 'is_selected() 1');
ok($field->is_selected('grape'), 'is_selected() 2');
ok(!$field->is_selected('apple'), 'is_selected() 3');
ok(!$field->is_selected('foo'), 'is_selected() 4');

ok($field->has_value('orange'), 'has_value() 1');
ok($field->has_value('grape'), 'has_value() 2');
ok(!$field->has_value('apple'), 'has_value() 3');
ok(!$field->has_value('foo'), 'has_value() 4');

$field->add_options(pear => 'Pear', berry => 'Berry');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option selected value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(</optgroup>),
  'add_options() hash');

$field->add_options(Rose::HTML::Form::Field::Option->new(value => 'squash', label => 'Squash'),
                    Rose::HTML::Form::Field::Option->new(value => 'cherry', label => 'Cherry'));

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option selected value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'add_options() objects');

is($field->html_hidden_field, 
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'html_hidden_field()');

is($field->html_hidden_fields, 
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'html_hidden_fields()');

is(join("\n", map { $_->html } $field->hidden_field),
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'hidden_field()');

is(join("\n", map { $_->html } $field->hidden_fields),
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'hidden_fields()');

$field->clear;

is(join('', $field->internal_value), '', 'clear() 1');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'clear() 2');

$field->reset;

is(join('', $field->internal_value), 'apple', 'reset() 1');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'reset() 2');

$field->default_value(undef);

is(join('', $field->internal_value), '', 'reset() 3');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'reset() 4');

$field->add_value('pear');

is(join('', $field->internal_value), 'pear', 'add_value() 2');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option selected value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'add_value() 3');

$field->add_values('squash', 'cherry');

is(join(',', $field->internal_value), 'cherry,pear,squash', 'add_values() 2');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option selected value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option selected value="squash">Squash</option>\n) .
  qq(<option selected value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'add_values() 3');

$field->reset;

is(join(',', $field->internal_value), '', 'reset() 5');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'reset() 6');

$field->default('orange');

is(join(',', $field->internal_value), 'orange', 'reset() 7');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'reset() 8');

$field->clear;

is(join(',', $field->internal_value), '', 'clear() 3');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'clear() 4');

$field->option('apple')->short_label('1.0');

is($field->html_field, 
  qq(<optgroup label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'option short_label()');

$field->disabled(1);

is($field->html_field, 
  qq(<optgroup disabled label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'html_field() 3');

is($field->xhtml_field, 
  qq(<optgroup disabled="disabled" label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'xhtml_field() 2');

my $id = ref($field)->localizer->add_localized_message( 
  name => 'ORANGE_LABEL',
  text => 
  {
    en => 'Orange EN',
    xx => 'Le Orange',
  });

$field->option('orange')->label_id($id);

is($field->option('orange')->label->as_string, 'Orange EN', 'localized label 1');
is($field->xhtml_field, 
  qq(<optgroup disabled="disabled" label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange EN</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'localized label 2');

$field->localizer->locale('xx');

is($field->option('orange')->label->as_string, 'Le Orange', 'localized label 3');
is($field->xhtml_field, 
  qq(<optgroup disabled="disabled" label="Fruits">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Le Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</optgroup>),
  'localized label 4');

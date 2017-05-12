#!/usr/bin/perl -w

use strict;

use Test::More tests => 101;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Option');
  use_ok('Rose::HTML::Form::Field::OptionGroup');
  use_ok('Rose::HTML::Form::Field::SelectBox');
}

my $field = Rose::HTML::Form::Field::SelectBox->new(name => 'fruits');

ok(ref $field eq 'Rose::HTML::Form::Field::SelectBox', 'new()');

is(scalar @{ $field->children }, 0, 'children scalar 1');
is(scalar(() = $field->children), 0, 'children list 1');

$field->options(apple  => 'Apple',
                orange => 
                {
                  label => 'Orange',
                },
                Rose::HTML::Form::Field::Option->new(value => 'grape', label => 'Grape'));

is(scalar @{ $field->children }, 3, 'children scalar 2');
is(scalar(() = $field->children), 3, 'children list 2');

is($field->is_empty, 1, 'is_empty 1');

is(join(',', sort $field->labels), 'Apple,Grape,Orange,apple,grape,orange', 'labels()');

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'html_field() 1');

is($field->value_label('apple'), 'Apple', 'value_label()');

$field->size(6);

is($field->html_field, 
  qq(<select name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'size()');

$field->option('apple')->label('<b>Apple</b>');
$field->escape_html(0);

is($field->html_field, 
  qq(<select name="fruits" size="6">\n) .
  qq(<option value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'escape_html() 1');

$field->escape_html(1);

is($field->html_field, 
  qq(<select name="fruits" size="6">\n) .
  qq(<option value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'escape_html() 2');

$field->option('apple')->label('Apple');

$field->default('apple');

is($field->html_field, 
  qq(<select name="fruits" size="6">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'default()');

is($field->value_label, 'Apple', 'value_label()');

$field->input_value('orange');

is($field->xhtml_field, 
  qq(<select name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected="selected" value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'value() 1');

is($field->is_empty, 0, 'is_empty 2');

$field->error("Do not pick orange!");

is($field->html, 
  qq(<select class="error" name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select><br>\n) .
  qq(<span class="error">Do not pick orange!</span>),
  'html()');

is($field->xhtml, 
  qq(<select class="error" name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected="selected" value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select><br />\n) .
  qq(<span class="error">Do not pick orange!</span>),
  'xhtml()');

$field->error(undef);

$field->multiple(1);

$field->add_value('apple');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'add_value() 1');

is(join(',', $field->internal_value), 'apple,orange', 'internal_value() 1');
is(join(',', @{$field->output_value}), 'apple,orange', 'output_value() 1');
is(join(',', @{$field->values}), 'apple,orange', 'values() 1');

$field->input_value(undef);

$field->add_values('orange', 'grape');

is($field->xhtml_field, 
  qq(<select multiple="multiple" name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected="selected" value="orange">Orange</option>\n) .
  qq(<option selected="selected" value="grape">Grape</option>\n) .
  qq(</select>),
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
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option selected value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(</select>),
  'add_options() hash');

$field->add_options(Rose::HTML::Form::Field::Option->new(value => 'squash', label => 'Squash'),
                    Rose::HTML::Form::Field::Option->new(value => 'cherry', label => 'Cherry'));

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option selected value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'add_options() objects');

is($field->html_hidden_field, 
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'html_hidden_field()');

is($field->xhtml_hidden_fields, 
  qq(<input name="fruits" type="hidden" value="orange" />\n) .
  qq(<input name="fruits" type="hidden" value="grape" />),
  'xhtml_hidden_fields()');

is(join("\n", map { $_->html } $field->hidden_field),
  qq(<input name="fruits" type="hidden" value="orange">\n) .
  qq(<input name="fruits" type="hidden" value="grape">),
  'hidden_field() html');

is(join("\n", map { $_->xhtml } $field->hidden_fields),
  qq(<input name="fruits" type="hidden" value="orange" />\n) .
  qq(<input name="fruits" type="hidden" value="grape" />),
  'hidden_fields() xhtml');

$field->clear;

is(join('', $field->internal_value), '', 'clear() 1');

$field->multiple(0);

is(scalar $field->internal_value, undef, 'clear() 2');

$field->multiple(1);

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'clear() 3');

$field->reset;

is(join('', $field->internal_value), 'apple', 'reset() 1');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'reset() 2');

$field->default_value(undef);

is(join('', $field->internal_value), '', 'reset() 3');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'reset() 4');

$field->add_value('pear');

is(join('', $field->internal_value), 'pear', 'add_value() 2');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option selected value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'add_value() 3');

$field->add_values('squash', 'cherry');

is(join(',', $field->internal_value), 'cherry,pear,squash', 'add_values() 2');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option selected value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option selected value="squash">Squash</option>\n) .
  qq(<option selected value="cherry">Cherry</option>\n) .
  qq(</select>),
  'add_values() 3');

$field->reset;

is(join(',', $field->internal_value), '', 'reset() 5');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'reset() 6');

$field->default('orange');

is(join(',', $field->internal_value), 'orange', 'reset() 7');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'reset() 8');

$field->clear;

is(join(',', $field->internal_value), '', 'clear() 4');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'clear() 5');

$field->option('apple')->short_label('1.0');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'option short_label()');

$field->add_value('apple');

# my $group = Rose::HTML::Form::Field::OptionGroup->new(label => 'Group 1');
# 
# $group->options(juji  => 'Juji',
#                 peach => 'Peach');
# 
# $field->add_options($group);

$field->add_options
(
  'Group 1' =>
  [
    juji  => 
    {
      label => 'Juji',
    },
    peach => 'Peach'
  ],
);

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group 1">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'option group html_field() 1');

$field->xhtml_hidden_fields;

$field->add_value('peach');

is(join(',', $field->input_value), 'apple,peach', 'input_value() 3');
is(join(',', $field->internal_value), 'apple,peach', 'internal_value() 3');
is(join(',', @{$field->output_value}), 'apple,peach', 'output_value() 3');
is(join(',', @{$field->values}), 'apple,peach', 'values() 3');

is($field->xhtml_field, 
  qq(<select multiple="multiple" name="fruits" size="6">\n) .
  qq(<option label="1.0" selected="selected" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group 1">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option selected="selected" value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'option group xhtml_field() 1');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group 1">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option selected value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'option group html_field() 2');

$field->input_value('juji');

is(join(',', $field->input_value), 'juji', 'input_value() 4');
is(join(',', $field->internal_value), 'juji', 'internal_value() 4');
is(join(',', @{$field->output_value}), 'juji', 'output_value() 4');
is(join(',', @{$field->values}), 'juji', 'values() 4');

$field->option('peach')->short_label('2.1');
$field->option_group('Group 1')->label('Group1');

is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group1">\n) .
  qq(<option selected value="juji">Juji</option>\n) .
  qq(<option label="2.1" value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'option group html_field() 3');

$field->xhtml_hidden_fields;

$field->add_value('apple');

is($field->html_hidden_field, 
  qq(<input name="fruits" type="hidden" value="apple">\n) .
  qq(<input name="fruits" type="hidden" value="juji">),
  'option group html_hidden_field()');

is($field->xhtml_hidden_fields, 
  qq(<input name="fruits" type="hidden" value="apple" />\n) .
  qq(<input name="fruits" type="hidden" value="juji" />),
  'option group xhtml_hidden_fields()');

is(join("\n", map { $_->html } $field->hidden_field),
  qq(<input name="fruits" type="hidden" value="apple">\n) .
  qq(<input name="fruits" type="hidden" value="juji">),
  'option group hidden_field() html');

is(join("\n", map { $_->xhtml } $field->hidden_fields),
  qq(<input name="fruits" type="hidden" value="apple" />\n) .
  qq(<input name="fruits" type="hidden" value="juji" />),
  'option group hidden_fields() xhtml');

my $id = ref($field)->localizer->add_localized_message( 
  name => 'ORANGE_LABEL',
  text => 
  {
    en => 'Orange EN',
    xx => 'Le Orange',
  });

$field->option('orange')->label_id($id);

is($field->option('orange')->label->as_string, 'Orange EN', 'localized label 1');
is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange EN</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group1">\n) .
  qq(<option selected value="juji">Juji</option>\n) .
  qq(<option label="2.1" value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'localized label 2');

$field->localizer->locale('xx');

is($field->option('orange')->label->as_string, 'Le Orange', 'localized label 3');
is($field->html_field, 
  qq(<select multiple name="fruits" size="6">\n) .
  qq(<option label="1.0" selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Le Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(<optgroup label="Group1">\n) .
  qq(<option selected value="juji">Juji</option>\n) .
  qq(<option label="2.1" value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'localized label 4');

$field->disabled(1);

$field = Rose::HTML::Form::Field::SelectBox->new(name => 'fruits');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

my $group = Rose::HTML::Form::Field::OptionGroup->new(label => 'Others');

$group->options(juji  => 'Juji',
                peach => 'Peach');

$field->add_options($group);

my $field2 = 
  Rose::HTML::Form::Field::SelectBox->new(
    name    => 'fruits',
    options =>
    [
      apple  => 'Apple',
      orange => 'Orange',
      grape  => 'Grape',
      Others =>
      [
        juji  => { label => 'Juji' },
        peach => { label => 'Peach' },
      ],
    ]);

is($field->xhtml, $field2->xhtml, 'nested option group 1');

$field->option('grape')->hide;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 1');

is($field->xhtml_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 2');

$group->hide;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(</select>),
  'hidden 3');

is($field->xhtml_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(</select>),
  'hidden 4');

$field->option('grape')->show;
$group->show;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 5');

$group->hide_all_options;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 7');

$field->hide_all_options;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n\n) .
  qq(</select>),
  'hidden 8');

$field->show_all_options;

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 9');

$field->delete_option('grape');

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'delete 1');

$field->delete_options('grape', 'peach', 'apple');

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'delete 2');

$field->delete_option_group('Others', 'nonesuch');

is($field->html_field, 
  qq(<select name="fruits" size="5">\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(</select>),
  'delete 3');


$field = Rose::HTML::Form::Field::SelectBox->new(name => 'fruits');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

my $i = 1;

foreach my $name (qw(items options))
{
  my $method = "${name}_html_attr";

  $field->$method(class => 'bar');

  is($field->xhtml_field, 
    qq(<select name="fruits" size="5">\n) .
    qq(<option class="bar" value="apple">Apple</option>\n) .
    qq(<option class="bar" value="orange">Orange</option>\n) .
    qq(<option class="bar" value="grape">Grape</option>\n) .
    qq(</select>),
    "$method " . $i++);

  is($field->$method('class'), 'bar', "$method " . $i++);

  $method = "delete_${name}_html_attr";

  $field->$method('class');

  is($field->xhtml_field, 
    qq(<select name="fruits" size="5">\n) .
    qq(<option value="apple">Apple</option>\n) .
    qq(<option value="orange">Orange</option>\n) .
    qq(<option value="grape">Grape</option>\n) .
    qq(</select>),
    "$method " . $i++);    
}

$field->add_option('');

$field->input_value('apple');

is($field->is_empty, 0, 'is_empty 3');

$field->input_value('');

is($field->is_empty, 1, 'is_empty 4');

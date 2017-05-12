#!/usr/local/bin/perl -w

use strict;

use Test::More tests => 72;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Option');
  use_ok('Rose::HTML::Form::Field::PopUpMenu');
}

my $field = Rose::HTML::Form::Field::PopUpMenu->new(name => 'fruits');

ok(ref $field eq 'Rose::HTML::Form::Field::PopUpMenu', 'new()');

is(scalar @{ $field->children }, 0, 'children scalar 1');
is(scalar(() = $field->children), 0, 'children list 1');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

is(scalar @{ $field->children }, 3, 'children scalar 2');
is(scalar(() = $field->children), 3, 'children list 2');

is($field->is_empty, 1, 'is_empty 1');

is(join(',', sort $field->labels), 'Apple,Grape,Orange,apple,grape,orange', 'labels()');

$field->error('bar');
$field->clear;
ok(!defined $field->error, 'clear error');

$field->error('foo');
$field->reset;
ok(!defined $field->error, 'reset error');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'html_field() 1');

is($field->value_label('apple'), 'Apple', 'label()');

$field->option('apple')->label('<b>Apple</b>');
$field->escape_html(0);

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'escape_html() 1');

$field->escape_html(1);

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">&lt;b&gt;Apple&lt;/b&gt;</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'escape_html() 1');

$field->option('apple')->label('Apple');

$field->default('apple');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'default()');

$field->value('orange');

is(($field->input_value)[0], 'orange', 'input_value()');
is(($field->internal_value)[0], 'orange', 'internal_value() 1');
is($field->internal_value, 'orange', 'internal_value() 2');
is(($field->output_value)[0], 'orange', 'output_value()');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'value() 1');

is($field->is_empty, 0, 'is_empty 2');

$field->error("Do not pick orange!");

is($field->html, 
  qq(<select class="error" name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select><br>\n) .
  qq(<span class="error">Do not pick orange!</span>),
  'html()');

is($field->xhtml, 
  qq(<select class="error" name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected="selected" value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select><br />\n) .
  qq(<span class="error">Do not pick orange!</span>),
  'html()');

$field->error(undef);

ok($field->is_selected('orange'), 'is_selected() 1');
ok(!$field->is_selected('apple'), 'is_selected() 2');
ok(!$field->is_selected('foo'), 'is_selected() 3');

ok($field->has_value('orange'), 'has_value() 1');
ok(!$field->has_value('apple'), 'has_value() 2');
ok(!$field->has_value('foo'), 'has_value() 3');

$field->add_options(pear => 'Pear', berry => 'Berry');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(</select>),
  'add_options() hash');

$field->add_options(Rose::HTML::Form::Field::Option->new(value => 'squash', label => 'Squash'),
                    Rose::HTML::Form::Field::Option->new(value => 'cherry', label => 'Cherry'));

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option selected value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'add_options() objects');

is($field->html_hidden_field, 
  qq(<input name="fruits" type="hidden" value="orange">),
  'html_hidden_field()');

is($field->html_hidden_fields, 
  qq(<input name="fruits" type="hidden" value="orange">),
  'html_hidden_fields()');

is(join("\n", map { $_->html } $field->hidden_field),
  qq(<input name="fruits" type="hidden" value="orange">),
  'hidden_field()');

is(join("\n", map { $_->html } $field->hidden_fields),
  qq(<input name="fruits" type="hidden" value="orange">),
  'hidden_fields()');

$field->clear;

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'clear()');

$field->reset;

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'reset()');

$field->input_value('apple');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'input_value() 2');

eval { $field->input_value([ 'apple', 'cherry' ]) };

ok($@, 'multiple values');

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
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange EN</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'localized label 2');

$field->localizer->locale('xx');

is($field->option('orange')->label->as_string, 'Le Orange', 'localized label 3');
is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Le Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'localized label 4');

$field->localizer->locale('en');
$field->locale('xx');

is($field->option('orange')->label->as_string, 'Le Orange', 'localized label 3.1');
is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Le Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">Squash</option>\n) .
  qq(<option value="cherry">Cherry</option>\n) .
  qq(</select>),
  'localized label 4.1');

$field->localizer->locale('xx');
$field->locale(undef);

$field->labels({ cherry => 'CHERRY', squash => 'SQUASH' });

$field->label_ids(grape => $id);

is($field->option('grape')->label->as_string, 'Le Orange', 'localized label 4');
is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">Apple</option>\n) .
  qq(<option value="orange">Le Orange</option>\n) .
  qq(<option value="grape">Le Orange</option>\n) .
  qq(<option value="pear">Pear</option>\n) .
  qq(<option value="berry">Berry</option>\n) .
  qq(<option value="squash">SQUASH</option>\n) .
  qq(<option value="cherry">CHERRY</option>\n) .
  qq(</select>),
  'localized label 5');

$field->clear_labels;

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple"></option>\n) .
  qq(<option value="orange"></option>\n) .
  qq(<option value="grape"></option>\n) .
  qq(<option value="pear"></option>\n) .
  qq(<option value="berry"></option>\n) .
  qq(<option value="squash"></option>\n) .
  qq(<option value="cherry"></option>\n) .
  qq(</select>),
  'clear labels 1');

$field->option('grape')->hidden(1);

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple"></option>\n) .
  qq(<option value="orange"></option>\n) .
  qq(<option value="pear"></option>\n) .
  qq(<option value="berry"></option>\n) .
  qq(<option value="squash"></option>\n) .
  qq(<option value="cherry"></option>\n) .
  qq(</select>),
  'hidden 1');

is($field->xhtml_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected="selected" value="apple"></option>\n) .
  qq(<option value="orange"></option>\n) .
  qq(<option value="pear"></option>\n) .
  qq(<option value="berry"></option>\n) .
  qq(<option value="squash"></option>\n) .
  qq(<option value="cherry"></option>\n) .
  qq(</select>),
  'hidden 2');

$field->option('grape')->hidden(0);

$field->reset_labels;

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option selected value="apple">apple</option>\n) .
  qq(<option value="orange">orange</option>\n) .
  qq(<option value="grape">grape</option>\n) .
  qq(<option value="pear">pear</option>\n) .
  qq(<option value="berry">berry</option>\n) .
  qq(<option value="squash">squash</option>\n) .
  qq(<option value="cherry">cherry</option>\n) .
  qq(</select>),
  'reset labels 1');

$field->disabled(1);

$field = Rose::HTML::Form::Field::PopUpMenu->new(name => 'fruits');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

my $group = Rose::HTML::Form::Field::OptionGroup->new(label => 'Others');

$group->options(juji  => 'Juji',
                peach => 'Peach');

$field->add_options($group);

my $field2 = 
  Rose::HTML::Form::Field::PopUpMenu->new(
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

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 3');

is($field->xhtml_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 4');

$group->option('juji')->hide;

is($field->xhtml_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 4.1');

$group->option('juji')->show;
$field->option('peach')->hide;

is($field->xhtml_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'hidden 4.2');

$group->option('peach')->show;
$group->hidden(1);

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'hidden 5');

is($field->xhtml_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<option value="grape">Grape</option>\n) .
  qq(</select>),
  'hidden 6');

$field->show_all_options;
$field->delete_option('grape');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<option value="orange">Orange</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(<option value="peach">Peach</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'delete 1');

$field->delete_options('grape', 'peach', 'orange');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(<optgroup label="Others">\n) .
  qq(<option value="juji">Juji</option>\n) .
  qq(</optgroup>\n) .
  qq(</select>),
  'delete 2');

$field->delete_option_group('Others', 'nonesuch');

is($field->html_field, 
  qq(<select name="fruits" size="1">\n) .
  qq(<option value="apple">Apple</option>\n) .
  qq(</select>),
  'delete 3');

$field = Rose::HTML::Form::Field::PopUpMenu->new(name => 'fruits');

$field->options(apple  => 'Apple',
                orange => 'Orange',
                grape  => 'Grape');

my $i = 1;

foreach my $name (qw(items options))
{
  my $method = "${name}_html_attr";

  $field->$method(class => 'bar');

  is($field->xhtml_field, 
    qq(<select name="fruits" size="1">\n) .
    qq(<option class="bar" value="apple">Apple</option>\n) .
    qq(<option class="bar" value="orange">Orange</option>\n) .
    qq(<option class="bar" value="grape">Grape</option>\n) .
    qq(</select>),
    "$method " . $i++);

  is($field->$method('class'), 'bar', "$method " . $i++);

  $method = "delete_${name}_html_attr";

  $field->$method('class');

  is($field->xhtml_field, 
    qq(<select name="fruits" size="1">\n) .
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

$field->clear;

is($field->is_empty, 1, 'is_empty 4');

is(scalar $field->internal_value, undef, 'undef internal value');

$field->input_value('orange');

is(scalar $field->internal_value, 'orange', 'orange internal value');

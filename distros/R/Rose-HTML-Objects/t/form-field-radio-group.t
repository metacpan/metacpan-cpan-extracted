#!/usr/bin/perl -w

use strict;

use Test::More tests => 62;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::RadioButton');
  use_ok('Rose::HTML::Form::Field::RadioButtonGroup');
}

my $field = Rose::HTML::Form::Field::RadioButtonGroup->new(name => 'fruits');

ok(ref $field eq 'Rose::HTML::Form::Field::RadioButtonGroup', 'new()');

is(scalar @{ $field->children }, 0, 'children scalar 1');
is(scalar(() = $field->children), 0, 'children list 1');

$field->choices(apple  => 'Apple',
                orange => 
                {
                  label => 'Orange',
                },
                Rose::HTML::Form::Field::RadioButton->new(value => 'grape', label => 'Grape'));

is(scalar @{ $field->children }, 0, 'children scalar 2');
is(scalar(() = $field->children), 0, 'children list 2');

is(join(',', sort $field->labels), 'Apple,Grape,Orange,apple,grape,orange', 'labels()');

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'html_field() 1');

$field = 
  Rose::HTML::Form::Field::RadioButtonGroup->new(
    name => 'fruits',
    choices =>
    [
      Rose::HTML::Form::Field::RadioButton->new(value => 'apple', label => 'Apple'),
      orange  => 'Orange',
      grape => 
      {
        label => 'Grape',
      }
    ]);

is($field->value_label('apple'), 'Apple', 'value_label()');

$field->radio_button('apple')->label('<b>Apple</b>');

$field->escape_html(0);

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label><b>Apple</b></label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'escape_html() 1');

$field->escape_html(1);

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>&lt;b&gt;Apple&lt;/b&gt;</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'escape_html() 1');

$field->radio_button('apple')->label('Apple');

$field->linebreak(0);

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label> ) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label> ) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'linebreak()');

$field->linebreak(1);

$field->html_linebreak('<br><br>');

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br><br>) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br><br>) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'html_linebreak()');

$field->html_linebreak("<br>\n");

$field->xhtml_linebreak('<br /><br />');

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br /><br />) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Orange</label><br /><br />) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label>),
  'xhtml_linebreak()');

$field->xhtml_linebreak("<br />\n");

$field->default_value('apple');

is($field->html_field, 
  qq(<input checked name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'default()');

$field->input_value('orange');

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input checked name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label>),
  'value() 1');

$field->value('orange');

$field->error("Do not pick orange!");

is($field->html, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input checked name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<span class="error">Do not pick orange!</span>),
  'html()');

$field->error(undef);

ok($field->is_checked('orange'), 'is_checked() 1');
ok(!$field->is_checked('grape'), 'is_checked() 2');
ok(!$field->is_checked('apple'), 'is_checked() 3');
ok(!$field->is_checked('foo'), 'is_checked() 4');

ok($field->has_value('orange'), 'has_value() 1');
ok(!$field->has_value('grape'), 'has_value() 2');
ok(!$field->has_value('apple'), 'has_value() 3');
ok(!$field->has_value('foo'), 'has_value() 4');

$field->add_radio_buttons(pear => 'Pear', berry => 'Berry');

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input checked name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label>),
  'add_radio_buttons() hash');

$field->add_radio_buttons(Rose::HTML::Form::Field::RadioButton->new(value => 'squash', label => 'Squash'),
                          Rose::HTML::Form::Field::RadioButton->new(value => 'cherry', label => 'Cherry'));

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input checked name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'add_radio_buttons() objects');

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
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'clear()');

my $table =<<"EOF";
<table class="radio-button-group">
<tr>
<td><input name="fruits" type="radio" value="apple"> <label>Apple</label><br>
<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>
<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>
<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>
<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>
<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>
<input name="fruits" type="radio" value="cherry"> <label>Cherry</label></td>
</tr>
</table>
EOF

is($field->html_table, $table, 'html_table() 1');

$table =<<"EOF";
<table border="1" cellpadding="1" cellspacing="2" class="zzz radio-button-group">
<tr>
<td><input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />
<input name="fruits" type="radio" value="orange" /> <label>Orange</label><br />
<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />
<input name="fruits" type="radio" value="pear" /> <label>Pear</label><br />
<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />
<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />
<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label></td>
</tr>
</table>
EOF

is($field->xhtml_table(class => 'yyy', table => { cellpadding => 1, cellspacing => 2, border => 1, class => 'zzz' }),
   $table, 'xhtml_table() 1');

$table =<<"EOF";
<table border="1" cellpadding="1" cellspacing="2" class="xxx radio-button-group">
<tr>
<td><input name="fruits" type="radio" value="apple"> <label>Apple</label><br>
<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>
<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>
<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>
<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>
<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>
<input name="fruits" type="radio" value="cherry"> <label>Cherry</label></td>
</tr>
</table>
EOF

is($field->html_table(class => 'xxx', table => { cellpadding => 1, cellspacing => 2, border => 1 }),
   $table, 'html_table() 2');

$table =<<"EOF";
<table class="radio-button-group">
<tr>
<td><input name="fruits" type="radio" value="apple"> <label>Apple</label><br>
<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>
<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>
<input name="fruits" type="radio" value="pear"> <label>Pear</label></td>
<td><input name="fruits" type="radio" value="berry"> <label>Berry</label><br>
<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>
<input name="fruits" type="radio" value="cherry"> <label>Cherry</label></td>
</tr>
</table>
EOF

is($field->html_table(columns => 2), $table, 'html_table() 3');

$field->reset;

is($field->html_field, 
  qq(<input checked name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'reset()');

is($field->xhtml_field, 
  qq(<input checked="checked" name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />\n) .
  qq(<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label>),
  'reset()');

my $id = ref($field)->localizer->add_localized_message( 
  name => 'ORANGE_LABEL',
  text => 
  {
    en => 'Orange EN',
    xx => 'Le Orange',
  });

$field->radio_button('orange')->label_id($id);

is($field->radio_button('orange')->label->as_string, 'Orange EN', 'localized label 1');
is($field->html_field, 
  qq(<input checked name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Orange EN</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'localized label 2');

$field->localizer->locale('xx');

is($field->radio_button('orange')->label->as_string, 'Le Orange', 'localized label 3');
is($field->html_field, 
  qq(<input checked name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Le Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'localized label 4');

$field->default('pear');
$field->input_value('squash');

is($field->internal_value, 'squash', 'internal_value() 1');
$field->clear;
$field->reset;

is($field->internal_value, 'pear', 'reset() 1');

is($field->html_field,
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Le Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input checked name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'reset() html 1');

is($field->xhtml_field,
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input checked="checked" name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />\n) .
  qq(<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label>),
  'reset() xhtml 1');

$field->input_value('grape');
$field->radio_button('grape')->hide;

is($field->internal_value, undef, 'hidden 0');

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Le Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'hidden 1');

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />\n) .
  qq(<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label>),
  'hidden 2');

$field->radio_button('grape')->show;

is($field->html_field, 
  qq(<input name="fruits" type="radio" value="apple"> <label>Apple</label><br>\n) .
  qq(<input name="fruits" type="radio" value="orange"> <label>Le Orange</label><br>\n) .
  qq(<input name="fruits" type="radio" value="grape"> <label>Grape</label><br>\n) .
  qq(<input name="fruits" type="radio" value="pear"> <label>Pear</label><br>\n) .
  qq(<input name="fruits" type="radio" value="berry"> <label>Berry</label><br>\n) .
  qq(<input name="fruits" type="radio" value="squash"> <label>Squash</label><br>\n) .
  qq(<input name="fruits" type="radio" value="cherry"> <label>Cherry</label>),
  'hidden 3');

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />\n) .
  qq(<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label>),
  'hidden 4');

$field->hide_all_radio_buttons;

is($field->xhtml_field, '', 'hidden 5');

$field->show_all_radio_buttons;

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input checked="checked" name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label><br />\n) .
  qq(<input name="fruits" type="radio" value="cherry" /> <label>Cherry</label>),
  'hidden 6');

$field->delete_radio_button('cherry');

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input checked="checked" name="fruits" type="radio" value="pear" /> <label>Pear</label><br />\n) .
  qq(<input name="fruits" type="radio" value="berry" /> <label>Berry</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label>),
  'delete 1');

$field->delete_radio_buttons('cherry', 'pear', 'berry');

is($field->xhtml_field, 
  qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
  qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
  qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
  qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label>),
  'delete 2');

my $i = 1;

foreach my $name (qw(items radio_buttons))
{
  my $method = "${name}_html_attr";

  $field->$method(class => 'bar');

  is($field->xhtml_field, 
    qq(<input class="bar" name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
    qq(<input class="bar" name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
    qq(<input class="bar" name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
    qq(<input class="bar" name="fruits" type="radio" value="squash" /> <label>Squash</label>),
    "$method " . $i++);

  is($field->$method('class'), 'bar', "$method " . $i++);

  $method = "delete_${name}_html_attr";

  $field->$method('class');

  is($field->xhtml_field, 
    qq(<input name="fruits" type="radio" value="apple" /> <label>Apple</label><br />\n) .
    qq(<input name="fruits" type="radio" value="orange" /> <label>Le Orange</label><br />\n) .
    qq(<input name="fruits" type="radio" value="grape" /> <label>Grape</label><br />\n) .
    qq(<input name="fruits" type="radio" value="squash" /> <label>Squash</label>),
    "$method " . $i++);    
}

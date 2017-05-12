#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 28;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::Text');
  use_ok('Rose::HTML::Form::Field::Compound');
}

my $field = Rose::HTML::Form::Field::Compound->new(name => 'date');
ok(ref $field && $field->isa('Rose::HTML::Form::Field::Compound'), 'new()');

$field->localizer->load_messages_from_file("$Bin/localized-messages");

is(scalar @{ $field->children }, 0, 'children scalar 1');
is(scalar(() = $field->children), 0, 'children list 1');

my %fields =
(
  month => Rose::HTML::Form::Field::Text->new(
             name => 'month', 
             size => 2),

  day   => Rose::HTML::Form::Field::Text->new(
             name => 'day', 
             size => 2),

  year  => Rose::HTML::Form::Field::Text->new(
             name => 'year', 
             size => 4),
);

ok($field->add_fields(%fields), 'add_fields()');

is(scalar @{ $field->children }, 0, 'children scalar 2');
is(scalar(() = $field->children), 0, 'children list 2');

is($field->field('month'), $fields{'month'}, 'field() set with field hash');

#is($field->field('date.month'), $fields{'month'}, 'field() addressing');

$field->init_fields(month => 12, day => 25, year => 1980);

is($field->field_value('day'), 25, 'field_value() 1');

is($field->html,
   qq(<input name="date.day" size="2" type="text" value="25">) .
   qq(<input name="date.month" size="2" type="text" value="12">) .
   qq(<input name="date.year" size="4" type="text" value="1980">), 'html()');

is($field->html_field,
   qq(<input name="date.day" size="2" type="text" value="25">) .
   qq(<input name="date.month" size="2" type="text" value="12">) .
   qq(<input name="date.year" size="4" type="text" value="1980">), 'html_field()');

is($field->xhtml,
   qq(<input name="date.day" size="2" type="text" value="25" />) .
   qq(<input name="date.month" size="2" type="text" value="12" />) .
   qq(<input name="date.year" size="4" type="text" value="1980" />), 'xhtml()');

is($field->xhtml_field,
   qq(<input name="date.day" size="2" type="text" value="25" />) .
   qq(<input name="date.month" size="2" type="text" value="12" />) .
   qq(<input name="date.year" size="4" type="text" value="1980" />), 'xhtml_field()');

is(join("\n", map { $_->html_field } $field->fields),
   qq(<input name="date.day" size="2" type="text" value="25">\n) .
   qq(<input name="date.month" size="2" type="text" value="12">\n) .
   qq(<input name="date.year" size="4" type="text" value="1980">), 'html field test');

is($field->html_hidden_fields,
   qq(<input name="date.day" type="hidden" value="25">\n) .
   qq(<input name="date.month" type="hidden" value="12">\n) .
   qq(<input name="date.year" type="hidden" value="1980">),
   'html_hidden_fields()');

is($field->xhtml_hidden_fields,
   qq(<input name="date.day" type="hidden" value="25" />\n) .
   qq(<input name="date.month" type="hidden" value="12" />\n) .
   qq(<input name="date.year" type="hidden" value="1980" />),
   'mdy xhtml_hidden_fields()');

is($field->html_hidden_field,
   qq(<input name="date.day" type="hidden" value="25">\n) .
   qq(<input name="date.month" type="hidden" value="12">\n) .
   qq(<input name="date.year" type="hidden" value="1980">),
   'html_hidden_field() 1');

is($field->xhtml_hidden_field,
   qq(<input name="date.day" type="hidden" value="25" />\n) .
   qq(<input name="date.month" type="hidden" value="12" />\n) .
   qq(<input name="date.year" type="hidden" value="1980" />),
   'mdy xhtml_hidden_field() 1');

{
  no warnings;
  *Rose::HTML::Form::Field::Compound::output_value = sub { '12/25/1980' };
}

is($field->html_hidden_field,
   qq(<input name="date" type="hidden" value="12/25/1980">),
   'html_hidden_field() 2');

is($field->xhtml_hidden_field,
   qq(<input name="date" type="hidden" value="12/25/1980" />),
   'xhtml_hidden_field() 2');

$field->clear();

is(join("\n", map { $_->html_field } $field->fields),
   qq(<input name="date.day" size="2" type="text" value="">\n) .
   qq(<input name="date.month" size="2" type="text" value="">\n) .
   qq(<input name="date.year" size="4" type="text" value="">), 'clear()');

my $id = ref($field)->localizer->add_localized_message( 
  name => 'DAY_FIELD_LABEL',
  text => 
  {
    en => 'Day',
    xx => 'Le Day',
  });

$field->field('day')->label_id($id);
$field->required(1);
$field->field('month')->required(1);
$field->field('month')->input_value(2);
$field->validate;

is($field->error, 'Missing Day, year.', 'error 1');

$field->locale('xx');
is($field->error, 'Missing Le Day : year.', 'error 2');

$field->locale('fr');
is($field->error, 'Les champs Day, year manquent.', 'error 3');

$field->field('year')->input_value(2000);
$field->validate;

$field->locale('en');
is($field->error, 'Missing Day.', 'error 4');

$field->locale('xx');
is($field->error, 'Missing Le Day.', 'error 5');

$field->locale('fr');
is($field->error, 'Le champ Day manque.', 'error 6');

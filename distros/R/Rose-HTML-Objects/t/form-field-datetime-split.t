#!/usr/bin/perl -w

use strict;

use Test::More tests => 73;

BEGIN 
{
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MonthDayYear');
  use_ok('Rose::HTML::Form::Field::DateTime::Split::MDYHMS');
  use_ok('DateTime');
  use_ok('Rose::DateTime::Util');
}

# Test to see if we can creat local DateTimes
eval { DateTime->now(time_zone => 'local') };

# Use UTC if we can't
Rose::DateTime::Util->time_zone('UTC')  if($@);

#
# Rose::HTML::Form::Field::DateTime::Split::MonthDayYear
#

my $field = Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'date',  
  value       => '12/25/1984',
  default     => '1/1/2000');

ok(ref $field eq 'Rose::HTML::Form::Field::DateTime::Split::MonthDayYear', 'mdy new()');

is($field->html_field, 
  '<span class="date">' .
  '<input class="month" maxlength="2" name="date.month" size="2" type="text" value="12">/' .
  '<input class="day" maxlength="2" name="date.day" size="2" type="text" value="25">/' .
  '<input class="year" maxlength="4" name="date.year" size="4" type="text" value="1984"></span>',
  'mdy html_field() 1');

is($field->xhtml_field,
  '<span class="date">' .
  '<input class="month" maxlength="2" name="date.month" size="2" type="text" value="12" />/' .
  '<input class="day" maxlength="2" name="date.day" size="2" type="text" value="25" />/' .
  '<input class="year" maxlength="4" name="date.year" size="4" type="text" value="1984" /></span>',
  'mdy xhtml_field()');

$field->field('month')->class('mm');
$field->field('day')->class('dd');
$field->field('year')->class('yyyy');

is($field->html_field, 
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="date.month" size="2" type="text" value="12">/' .
  '<input class="dd" maxlength="2" name="date.day" size="2" type="text" value="25">/' .
  '<input class="yyyy" maxlength="4" name="date.year" size="4" type="text" value="1984"></span>',
  'mdy html_field() 2');

$field->clear;

is($field->internal_value, undef, 'mdy internal_value() 1');

is($field->html_field, 
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="date.month" size="2" type="text" value="">/' .
  '<input class="dd" maxlength="2" name="date.day" size="2" type="text" value="">/' .
  '<input class="yyyy" maxlength="4" name="date.year" size="4" type="text" value=""></span>',
  'mdy html_field() 3');

$field->reset;

is($field->internal_value->strftime('%m/%d/%Y'), '01/01/2000', 'mdy internal_value() 2');

is($field->html_field, 
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="date.month" size="2" type="text" value="01">/' .
  '<input class="dd" maxlength="2" name="date.day" size="2" type="text" value="01">/' .
  '<input class="yyyy" maxlength="4" name="date.year" size="4" type="text" value="2000"></span>',
  'mdy html_field() 4');

is($field->html_hidden_fields,
   qq(<input class="dd" name="date.day" type="hidden" value="01">\n) .
   qq(<input class="mm" name="date.month" type="hidden" value="01">\n) .
   qq(<input class="yyyy" name="date.year" type="hidden" value="2000">),
   'mdy html_hidden_fields()');

is($field->xhtml_hidden_fields,
   qq(<input class="dd" name="date.day" type="hidden" value="01" />\n) .
   qq(<input class="mm" name="date.month" type="hidden" value="01" />\n) .
   qq(<input class="yyyy" name="date.year" type="hidden" value="2000" />),
   'mdy xhtml_hidden_fields()');

is($field->html_hidden_field,
   qq(<input name="date" type="hidden" value="01/01/2000">),
   'mdy html_hidden_field()');

is($field->xhtml_hidden_field,
   qq(<input name="date" type="hidden" value="01/01/2000" />),
   'mdy xhtml_hidden_field()');

$field->input_value('foo');
is($field->error, undef, 'mdy error() 1');

is($field->validate, 0, 'mdy validate() 1');
ok($field->error =~ /\S/, 'mdy error() 2');

is($field->internal_value, undef, 'mdy internal_value() 3');
is($field->input_value, 'foo', 'mdy input_value() 1');
is($field->output_value, 'foo', 'mdy output_value() 1');

use Rose::HTML::Form;
my $form = Rose::HTML::Form->new;
$form->add_fields(start => Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(name => 'start'));
$form->params('start.month' => 1);
$form->init_fields;

ok(!$form->field('start')->validate, 'mdy validate partial 1');
ok($form->field('start')->error, 'mdy validate partial 2');

$field = Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(name => 'start');

ok($field->validate, 'mdy empty validate 1');
ok($field->is_empty, 'mdy empty is_empty 1');
ok(!$field->is_full, 'mdy empty is_full 1');
ok(!$field->has_partial_value, 'mdy empty has_partial_value');

$field->field('month')->input_value('');
$field->field('day')->input_value('');
$field->field('year')->input_value('');

ok($field->validate, 'mdy empty validate 2');
ok($field->is_empty, 'mdy empty is_empty 2');
ok(!$field->is_full, 'mdy empty is_full 2');

#
# Rose::HTML::Form::Field::DateTime::Split::MDYHMS
#

$field = Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'datetime',  
  value       => '12/25/1984 12:34:56pm',
  default     => '1/2/2000 8am');

ok(ref $field eq 'Rose::HTML::Form::Field::DateTime::Split::MDYHMS', 'mdyhms new()');

is($field->html_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="month" maxlength="2" name="datetime.date.month" size="2" type="text" value="12">/' .
  '<input class="day" maxlength="2" name="datetime.date.day" size="2" type="text" value="25">/' .
  '<input class="year" maxlength="4" name="datetime.date.year" size="4" type="text" value="1984"></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="datetime.time.hour" size="2" type="text" value="12">:' .
  '<input class="minute" maxlength="2" name="datetime.time.minute" size="2" type="text" value="34">:' .
  '<input class="second" maxlength="2" name="datetime.time.second" size="2" type="text" value="56">' .
  qq(<select class="ampm" name="datetime.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms html_field() 1');

is($field->xhtml_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="month" maxlength="2" name="datetime.date.month" size="2" type="text" value="12" />/' .
  '<input class="day" maxlength="2" name="datetime.date.day" size="2" type="text" value="25" />/' .
  '<input class="year" maxlength="4" name="datetime.date.year" size="4" type="text" value="1984" /></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="datetime.time.hour" size="2" type="text" value="12" />:' .
  '<input class="minute" maxlength="2" name="datetime.time.minute" size="2" type="text" value="34" />:' .
  '<input class="second" maxlength="2" name="datetime.time.second" size="2" type="text" value="56" />' .
  qq(<select class="ampm" name="datetime.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected="selected" value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms xhtml_field() 1');

$field->name('when');

is($field->html_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="month" maxlength="2" name="when.date.month" size="2" type="text" value="12">/' .
  '<input class="day" maxlength="2" name="when.date.day" size="2" type="text" value="25">/' .
  '<input class="year" maxlength="4" name="when.date.year" size="4" type="text" value="1984"></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="when.time.hour" size="2" type="text" value="12">:' .
  '<input class="minute" maxlength="2" name="when.time.minute" size="2" type="text" value="34">:' .
  '<input class="second" maxlength="2" name="when.time.second" size="2" type="text" value="56">' .
  qq(<select class="ampm" name="when.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms html_field() rename 1');

is($field->xhtml_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="month" maxlength="2" name="when.date.month" size="2" type="text" value="12" />/' .
  '<input class="day" maxlength="2" name="when.date.day" size="2" type="text" value="25" />/' .
  '<input class="year" maxlength="4" name="when.date.year" size="4" type="text" value="1984" /></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="when.time.hour" size="2" type="text" value="12" />:' .
  '<input class="minute" maxlength="2" name="when.time.minute" size="2" type="text" value="34" />:' .
  '<input class="second" maxlength="2" name="when.time.second" size="2" type="text" value="56" />' .
  qq(<select class="ampm" name="when.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected="selected" value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms xhtml_field() rename 1');

$field->name('datetime');

$field->field('date.month')->class('mm');
$field->field('date.day')->class('dd');
$field->field('date')->field('year')->class('yyy');
$field->field('date.year')->class('yyyy');

my $subfield = $field->field('date');

is($field->field('date'), $subfield, 'Subfield access 1');

$subfield = $field->field('date.year');

is($field->field('date')->field('year'), $subfield, 'Subfield access 2');

is($field->html_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="datetime.date.month" size="2" type="text" value="12">/' .
  '<input class="dd" maxlength="2" name="datetime.date.day" size="2" type="text" value="25">/' .
  '<input class="yyyy" maxlength="4" name="datetime.date.year" size="4" type="text" value="1984"></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="datetime.time.hour" size="2" type="text" value="12">:' .
  '<input class="minute" maxlength="2" name="datetime.time.minute" size="2" type="text" value="34">:' .
  '<input class="second" maxlength="2" name="datetime.time.second" size="2" type="text" value="56">' .
  qq(<select class="ampm" name="datetime.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms html_field() 2');

$field->reset;

is($field->internal_value->strftime('%m/%d/%Y %I:%M:%S %p'), '01/02/2000 08:00:00 AM', 'mdyhms internal_value() 2');

is($field->html_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="datetime.date.month" size="2" type="text" value="01">/' .
  '<input class="dd" maxlength="2" name="datetime.date.day" size="2" type="text" value="02">/' .
  '<input class="yyyy" maxlength="4" name="datetime.date.year" size="4" type="text" value="2000"></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="datetime.time.hour" size="2" type="text" value="08">:' .
  '<input class="minute" maxlength="2" name="datetime.time.minute" size="2" type="text" value="00">:' .
  '<input class="second" maxlength="2" name="datetime.time.second" size="2" type="text" value="00">' .
  qq(<select class="ampm" name="datetime.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option selected value="AM">AM</option>\n) .
  qq(<option value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms html_field() 3');

is($field->html_hidden_fields,
   qq(<input class="dd" name="datetime.date.day" type="hidden" value="02">\n) .
   qq(<input class="mm" name="datetime.date.month" type="hidden" value="01">\n) .
   qq(<input class="yyyy" name="datetime.date.year" type="hidden" value="2000">\n) .
   qq(<input name="datetime.time.ampm" type="hidden" value="AM">\n) .
   qq(<input class="hour" name="datetime.time.hour" type="hidden" value="08">\n) .
   qq(<input class="minute" name="datetime.time.minute" type="hidden" value="00">\n) .
   qq(<input class="second" name="datetime.time.second" type="hidden" value="00">),
   'mdyhms html_hidden_fields()');

is($field->xhtml_hidden_fields,
   qq(<input class="dd" name="datetime.date.day" type="hidden" value="02" />\n) .
   qq(<input class="mm" name="datetime.date.month" type="hidden" value="01" />\n) .
   qq(<input class="yyyy" name="datetime.date.year" type="hidden" value="2000" />\n) .
   qq(<input name="datetime.time.ampm" type="hidden" value="AM" />\n) .
   qq(<input class="hour" name="datetime.time.hour" type="hidden" value="08" />\n) .
   qq(<input class="minute" name="datetime.time.minute" type="hidden" value="00" />\n) .
   qq(<input class="second" name="datetime.time.second" type="hidden" value="00" />),
   'mdyhms xhtml_hidden_fields()');

is($field->html_hidden_field,
   qq(<input name="datetime" type="hidden" value="01/02/2000 08:00:00 AM">),
   'mdyhms html_hidden_field()');

is($field->xhtml_hidden_field,
   qq(<input name="datetime" type="hidden" value="01/02/2000 08:00:00 AM" />),
   'mdyhms xhtml_hidden_field()');

$field->input_value('foo');
is($field->error, undef, 'mdyhms error() 1');

is($field->validate, 0, 'mdyhms validate() 1');
ok($field->error =~ /\S/, 'mdyhms error() 2');

is($field->internal_value, undef, 'mdyhms internal_value() 3');
is($field->input_value, 'foo', 'mdyhms input_value() 2');
is($field->output_value, 'foo', 'mdyhms output_value() 2');

# Test partial values

$field->clear;

$field->field('date')->field('month')->input_value(12);

ok(!defined $field->internal_value, 'mdyhms month');

$field->field('date.day')->input_value(31);

ok(!defined $field->internal_value, 'mdyhms month, day');

$field->field('date')->field('year')->input_value(2001);

ok(!defined $field->internal_value, 'mdyhms month, day, year');

$field->field('time.hour')->input_value(12);

ok(!defined $field->internal_value, 'mdyhms month, day, year, hour');

$field->field('time')->field('ampm')->input_value('x');

ok(!defined $field->internal_value, 'mdyhms month, day, year, hour x');

$field->field('time')->field('ampm')->input_value('PM');

is($field->field('time')->internal_value, '12:00:00 PM', 'mdyhms time set');

$field->internal_value;

is($field->internal_value->strftime('%Y-%m-%d %I:%M:%S %p'), 
   '2001-12-31 12:00:00 PM', 'mdyhms month, day, year, hour am/pm');

$field->field('time.hour')->input_value(99);
$field->field('time.minute')->input_value(88);
$field->field('time.second')->input_value(77);

is($field->html_field, 
  '<span class="datetime">' .
  '<span class="date">' .
  '<input class="mm" maxlength="2" name="datetime.date.month" size="2" type="text" value="12">/' .
  '<input class="dd" maxlength="2" name="datetime.date.day" size="2" type="text" value="31">/' .
  '<input class="yyyy" maxlength="4" name="datetime.date.year" size="4" type="text" value="2001"></span> ' .
  '<span class="time">' .
  '<input class="hour" maxlength="2" name="datetime.time.hour" size="2" type="text" value="99">:' .
  '<input class="minute" maxlength="2" name="datetime.time.minute" size="2" type="text" value="88">:' .
  '<input class="second" maxlength="2" name="datetime.time.second" size="2" type="text" value="77">' .
  qq(<select class="ampm" name="datetime.time.ampm" size="1">\n) .
  qq(<option value=""></option>\n) .
  qq(<option value="AM">AM</option>\n) .
  qq(<option selected value="PM">PM</option>\n) .
  '</select></span></span>',
  'mdyhms html_field() 4');

$field = Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(name => 'dt');

$field->field('date.month')->input_value('');
$field->field('date.day')->input_value('');
$field->field('date.year')->input_value('');

$field->field('time.hour')->input_value('');
$field->field('time.minute')->input_value('');
$field->field('time.second')->input_value('');
$field->field('time.ampm')->input_value('');

ok($field->validate, 'mdyhms empty validate 1');
ok($field->is_empty, 'mdyhms empty is_empty 1');
ok(!$field->is_full, 'mdyhms empty is_full 1');

$field = 
  Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
    name => 'start', required => 1, label => 'Start');

my $ok = $field->validate;

ok(defined $ok, 'empty compound validate 1');
ok($ok == 0, 'empty compound validate 2');

is($field->error, 'Start is a required field.', 'empty compound error labeled');

$field = 
  Rose::HTML::Form::Field::DateTime::Split::MonthDayYear->new(
    name => 'start', required => 1);

$ok = $field->validate;
ok(defined $ok, 'empty compound validate 3');
ok($ok == 0, 'empty compound validate 4');

is($field->error, 'This is a required field.', 'empty compound error unlabeled');

$field->field('day')->input_value(5);

$ok = $field->validate;
ok(defined $ok, 'empty compound validate 5');
ok($ok == 0, 'empty compound validate 6');

is($field->error, 'Missing month, year.', 'empty compound error unlabeled');

$field->input_value('31/31/2007');

is($field->html_field, 
  '<span class="date">' .
  '<input class="month" maxlength="2" name="start.month" size="2" type="text" value="31">/' .
  '<input class="day" maxlength="2" name="start.day" size="2" type="text" value="31">/' .
  '<input class="year" maxlength="4" name="start.year" size="4" type="text" value="2007"></span>',
  'mdy html_field() 1');

is($field->xhtml_field, 
  '<span class="date">' .
  '<input class="month" maxlength="2" name="start.month" size="2" type="text" value="31" />/' .
  '<input class="day" maxlength="2" name="start.day" size="2" type="text" value="31" />/' .
  '<input class="year" maxlength="4" name="start.year" size="4" type="text" value="2007" /></span>',
  'mdy xhtml_field() 1');

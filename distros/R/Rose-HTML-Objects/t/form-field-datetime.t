#!/usr/bin/perl -w

use strict;

use Test::More tests => 173;

BEGIN 
{
  use_ok('Rose::DateTime::Util');
  use_ok('Rose::HTML::Form::Field::Date');
  use_ok('Rose::HTML::Form::Field::DateTime');
  use_ok('Rose::HTML::Form::Field::DateTime::StartDate');
  use_ok('Rose::HTML::Form::Field::DateTime::EndDate');
  use_ok('Rose::HTML::Form::Field::DateTime::Range');
}

# Test to see if we can creat local DateTimes
eval { DateTime->now(time_zone => 'local') };

# Use UTC if we can't
Rose::DateTime::Util->time_zone('UTC')  if($@);

my $field = Rose::HTML::Form::Field::DateTime->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'date',
  size        => 30,
  value       => '12/25/1984',
  default     => '1/1/2000');

ok(ref $field eq 'Rose::HTML::Form::Field::DateTime', 'new()');

is($field->html_field, '<input name="date" size="30" type="text" value="1984-12-25 12:00:00 AM">', 'html_field() 1');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="1984-12-25 12:00:00 AM" />', 'xhtml_field() 1');

my $date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 1');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '12/25/1984 00:00:00', 'internal_value() 2');
is($field->input_value, '12/25/1984', 'input_value() 1');
is($field->output_value, '1984-12-25 12:00:00 AM', 'output_value() 1');

$field->clear;

is($field->html_field, '<input name="date" size="30" type="text" value="">', 'html_field() 2');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="" />', 'xhtml_field() 2');

is($field->internal_value, undef, 'internal_value() 3');
is($field->input_value, undef, 'input_value() 2');
is($field->output_value, undef, 'output_value() 2');

$field->reset;

is($field->html_field, '<input name="date" size="30" type="text" value="2000-01-01 12:00:00 AM">', 'html_field() 3');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="2000-01-01 12:00:00 AM" />', 'xhtml_field() 3');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '01/01/2000 00:00:00', 'internal_value() 5');
is($field->input_value, '1/1/2000', 'input_value() 3');
is($field->output_value, '2000-01-01 12:00:00 AM', 'output_value() 3');

# Testing default size value
$field->delete_html_attr('size');

is($field->html_field, '<input name="date" size="25" type="text" value="2000-01-01 12:00:00 AM">', 'html_field() 4');
is($field->xhtml_field, '<input name="date" size="25" type="text" value="2000-01-01 12:00:00 AM" />', 'xhtml_field() 4');

is($field->validate, 1, 'validate() 1');

$field->input_value('foo');

is($field->internal_value, undef, 'internal_value() 6');
is($field->input_value, 'foo', 'input_value() 4');
is($field->output_value, 'foo', 'output_value() 4');

is($field->validate, 0, 'validate() 2');

$field->output_filter(sub { uc });

is($field->internal_value, undef, 'internal_value() 7');
is($field->input_value, 'foo', 'input_value() 5');
is($field->output_value, 'FOO', 'output_value() 5');

$field->output_filter(sub { lc });
$field->input_filter(sub { s/^-//; $_ });

$field->input_value('-2/2/2003');

is($field->validate, 1, 'validate() 3');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '02/02/2003 00:00:00', 'internal_value() 8');

is($field->input_value, '-2/2/2003', 'input_value() 6');
is($field->output_value, '2003-02-02 12:00:00 am', 'output_value() 6');

$field->time_zone('UTC');

$field->input_value('3/4/2005 12:34:56');

my $d1 = Rose::DateTime::Util::parse_date('3/4/2005 12:34:56', 'UTC');
my $d2 = $field->internal_value;

is(ref $d2, 'DateTime', 'internal_value() 9');

ok($d1 == $d2, 'time_zone() 1');

$field->output_format('%m.%d.%Y');
is($field->output_value, '03.04.2005', 'output_format()');

#
# Rose::HTML::Form::Field::Date
#

$field = Rose::HTML::Form::Field::Date->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'date',
  size        => 30,
  value       => '12/25/1984',
  default     => '1/1/2000');

ok(ref $field eq 'Rose::HTML::Form::Field::Date', 'new()');

is($field->html_field, '<input name="date" size="30" type="text" value="1984-12-25">', 'date html_field() 1');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="1984-12-25" />', 'date xhtml_field() 1');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'date internal_value() 1');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '12/25/1984 00:00:00', 'date internal_value() 2');
is($field->input_value, '12/25/1984', 'date input_value() 1');
is($field->output_value, '1984-12-25', 'date output_value() 1');

$field->clear;

is($field->html_field, '<input name="date" size="30" type="text" value="">', 'date html_field() 2');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="" />', 'date xhtml_field() 2');

is($field->internal_value, undef, 'internal_value() 3');
is($field->input_value, undef, 'input_value() 2');
is($field->output_value, undef, 'output_value() 2');

$field->reset;

is($field->html_field, '<input name="date" size="30" type="text" value="2000-01-01">', 'date html_field() 3');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="2000-01-01" />', 'date xhtml_field() 3');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'date internal_value() 4');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '01/01/2000 00:00:00', 'date internal_value() 5');
is($field->input_value, '1/1/2000', 'date input_value() 3');
is($field->output_value, '2000-01-01', 'date output_value() 3');

# Testing default size value
$field->delete_html_attr('size');

is($field->html_field, '<input name="date" size="25" type="text" value="2000-01-01">', 'date html_field() 4');
is($field->xhtml_field, '<input name="date" size="25" type="text" value="2000-01-01" />', 'date xhtml_field() 4');

is($field->validate, 1, 'validate() 1');

$field->input_value('foo');

is($field->internal_value, undef, 'internal_value() 6');
is($field->input_value, 'foo', 'date input_value() 4');
is($field->output_value, 'foo', 'date output_value() 4');

is($field->validate, 0, 'validate() 2');

$field->output_filter(sub { uc });

is($field->internal_value, undef, 'internal_value() 7');
is($field->input_value, 'foo', 'date input_value() 5');
is($field->output_value, 'FOO', 'date output_value() 5');

$field->output_filter(sub { lc });
$field->input_filter(sub { s/^-//; $_ });

$field->input_value('-2/2/2003');

is($field->validate, 1, 'validate() 3');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'date internal_value() 4');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '02/02/2003 00:00:00', 'date internal_value() 8');

is($field->input_value, '-2/2/2003', 'date input_value() 6');
is($field->output_value, '2003-02-02', 'date output_value() 6');

$field->time_zone('UTC');

$field->input_value('3/4/2005 12:34:56');

$d1 = Rose::DateTime::Util::parse_date('3/4/2005 00:00:00', 'UTC');
$d2 = $field->internal_value;

is(ref $d2, 'DateTime', 'date internal_value() 9');

ok($d1 == $d2, 'date time_zone() 1');

$field->output_format('%m.%d.%Y');
is($field->output_value, '03.04.2005', 'date output_format()');

#
# Rose::HTML::Form::Field::DateTime::StartDate
#

$field = Rose::HTML::Form::Field::DateTime::StartDate->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'date',
  size        => 30,
  value       => '12/25/1984',
  default     => '1/1/2000');

ok(ref $field eq 'Rose::HTML::Form::Field::DateTime::StartDate', 'new() - start date');

is($field->html_field, '<input name="date" size="30" type="text" value="1984-12-25 12:00:00 AM">', 'html_field() 1 - start date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="1984-12-25 12:00:00 AM" />', 'xhtml_field() 1 - start date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 1 - start date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '12/25/1984 00:00:00', 'internal_value() 2 - start date');
is($field->input_value, '12/25/1984', 'input_value() 1 - start date');
is($field->output_value, '1984-12-25 12:00:00 AM', 'output_value() 1 - start date');

$field->clear;

is($field->html_field, '<input name="date" size="30" type="text" value="">', 'html_field() 2 - start date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="" />', 'xhtml_field() 2 - start date');

is($field->internal_value, undef, 'internal_value() 3 - start date');
is($field->input_value, undef, 'input_value() 2 - start date');
is($field->output_value, undef, 'output_value() 2 - start date');

$field->reset;

is($field->html_field, '<input name="date" size="30" type="text" value="2000-01-01 12:00:00 AM">', 'html_field() 3 - start date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="2000-01-01 12:00:00 AM" />', 'xhtml_field() 3 - start date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4 - start date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '01/01/2000 00:00:00', 'internal_value() 5 - start date');
is($field->input_value, '1/1/2000', 'input_value() 3 - start date');
is($field->output_value, '2000-01-01 12:00:00 AM', 'output_value() 3 - start date');

# Testing default size value
$field->delete_html_attr('size');

is($field->html_field, '<input name="date" size="25" type="text" value="2000-01-01 12:00:00 AM">', 'html_field() 4 - start date');
is($field->xhtml_field, '<input name="date" size="25" type="text" value="2000-01-01 12:00:00 AM" />', 'xhtml_field() 4 - start date');

is($field->validate, 1, 'validate() 1 - start date');

$field->input_value('foo');

is($field->internal_value, undef, 'internal_value() 6 - start date');
is($field->input_value, 'foo', 'input_value() 4 - start date');
is($field->output_value, 'foo', 'output_value() 4 - start date');

is($field->validate, 0, 'validate() 2 - start date');

$field->output_filter(sub { uc });

is($field->internal_value, undef, 'internal_value() 7 - start date');
is($field->input_value, 'foo', 'input_value() 5 - start date');
is($field->output_value, 'FOO', 'output_value() 5 - start date');

$field->output_filter(sub { lc });
$field->input_filter(sub { s/^-//; $_ });

$field->input_value('-2/2/2003');

is($field->validate, 1, 'validate() 3 - start date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4 - start date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '02/02/2003 00:00:00', 'internal_value() 8 - start date');

is($field->input_value, '-2/2/2003', 'input_value() 6 - start date');
is($field->output_value, '2003-02-02 12:00:00 am', 'output_value() 6 - start date');

$field->time_zone('UTC');

$field->input_value('3/4/2005 12:34:56');

$d1 = Rose::DateTime::Util::parse_date('3/4/2005 12:34:56', 'UTC');
$d2 = $field->internal_value;

is(ref $d2, 'DateTime', 'internal_value() 9 - start date');

ok($d1 == $d2, 'time_zone() 1 - start date');

$field->output_format('%m.%d.%Y');
is($field->output_value, '03.04.2005', 'output_format() - start date');

#
# Rose::HTML::Form::Field::DateTime::EndDate
#

$field = Rose::HTML::Form::Field::DateTime::EndDate->new(
  label       => 'Date', 
  description => 'Some Date',
  name        => 'date',
  size        => 30,
  value       => '12/25/1984',
  default     => '1/1/2000');

ok(ref $field eq 'Rose::HTML::Form::Field::DateTime::EndDate', 'new()');

is($field->html_field, '<input name="date" size="30" type="text" value="1984-12-25 11:59:59 PM">', 'html_field() 1 - end date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="1984-12-25 11:59:59 PM" />', 'xhtml_field() 1 - end date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 1 - end date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '12/25/1984 23:59:59', 'internal_value() 2 - end date');
is($field->input_value, '12/25/1984', 'input_value() 1 - end date');
is($field->output_value, '1984-12-25 11:59:59 PM', 'output_value() 1 - end date');
is($date->nanosecond, 999999999, 'nanoseconds - end date');

$field->clear;

is($field->html_field, '<input name="date" size="30" type="text" value="">', 'html_field() 2 - end date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="" />', 'xhtml_field() 2 - end date');

is($field->internal_value, undef, 'internal_value() 3 - end date');
is($field->input_value, undef, 'input_value() 2 - end date');
is($field->output_value, undef, 'output_value() 2 - end date');

$field->reset;

is($field->html_field, '<input name="date" size="30" type="text" value="2000-01-01 11:59:59 PM">', 'html_field() 3 - end date');
is($field->xhtml_field, '<input name="date" size="30" type="text" value="2000-01-01 11:59:59 PM" />', 'xhtml_field() 3 - end date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4 - end date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '01/01/2000 23:59:59', 'internal_value() 5 - end date');
is($field->input_value, '1/1/2000', 'input_value() 3 - end date');
is($field->output_value, '2000-01-01 11:59:59 PM', 'output_value() 3 - end date');

# Testing default size value
$field->delete_html_attr('size');

is($field->html_field, '<input name="date" size="25" type="text" value="2000-01-01 11:59:59 PM">', 'html_field() 4 - end date');
is($field->xhtml_field, '<input name="date" size="25" type="text" value="2000-01-01 11:59:59 PM" />', 'xhtml_field() 4 - end date');

is($field->validate, 1, 'validate() 1 - end date');

$field->input_value('foo');

is($field->internal_value, undef, 'internal_value() 6 - end date');
is($field->input_value, 'foo', 'input_value() 4 - end date');
is($field->output_value, 'foo', 'output_value() 4 - end date');

is($field->validate, 0, 'validate() 2 - end date');

$field->output_filter(sub { uc });

is($field->internal_value, undef, 'internal_value() 7 - end date');
is($field->input_value, 'foo', 'input_value() 5 - end date');
is($field->output_value, 'FOO', 'output_value() 5 - end date');

$field->output_filter(sub { lc });
$field->input_filter(sub { s/^-//; $_ });

$field->input_value('-2/2/2003');

is($field->validate, 1, 'validate() 3 - end date');

$date = $field->internal_value;

is(ref $date, 'DateTime', 'internal_value() 4 - end date');
is($date->strftime('%m/%d/%Y %H:%M:%S'), '02/02/2003 23:59:59', 'internal_value() 8 - end date');

is($field->input_value, '-2/2/2003', 'input_value() 6 - end date');
is($field->output_value, '2003-02-02 11:59:59 pm', 'output_value() 6 - end date');

$field->time_zone('UTC');

$field->input_value('3/4/2005 12:34:56');

$d1 = Rose::DateTime::Util::parse_date('3/4/2005 12:34:56', 'UTC');
$d2 = $field->internal_value;

is(ref $d2, 'DateTime', 'internal_value() 9 - end date');

ok($d1 == $d2, 'time_zone() 1 - end date');

$field->output_format('%m.%d.%Y');
is($field->output_value, '03.04.2005', 'output_format() - end date');

#
# Rose::HTML::Form::Field::DateTime::Range
#

$field =
  Rose::HTML::Form::Field::DateTime::Range->new(
    label   => 'Date',
    name    => 'date',
    default => [ '1/2/2003', '4/5/2006' ]);

my($min, $max) = $field->internal_value; # DateTime objects

is($min->strftime('%Y-%m-%d'), "2003-01-02", 'internal_value 1 - date range');
is($max->strftime('%Y-%m-%d'), "2006-04-05", 'internal_value 2 - date range');

$field->input_value('5/6/1980 3pm to 2003-01-06 20:19:55');

my $dates = $field->internal_value;

is($dates->[0]->hour, 15, 'internal_value 3 - date range');
is($dates->[1]->hour, 20, 'internal_value 4 - date range');

is($dates->[0]->day_name, 'Tuesday', 'internal_value 5 - date range');

is($field->html_field, '<span class="date-range"><input maxlength="25" name="date.min" size="21" type="text" value="1980-05-06 03:00:00 PM"> - <input maxlength="25" name="date.max" size="21" type="text" value="2003-01-06 11:59:59 PM"></span>', 'html_field 1 - date range');

is($field->html, '<table class="date-range"><tr><td class="min"><input maxlength="25" name="date.min" size="21" type="text" value="1980-05-06 03:00:00 PM"></td><td> - </td><td class="max"><input maxlength="25" name="date.max" size="21" type="text" value="2003-01-06 11:59:59 PM"></td></tr></table>', 'html 1 - date range');

$field->input_value([ '2/3/2009', '7/8/2001' ]);

ok(!$field->validate, 'validate 1 - date range');

is($field->html, '<table class="date-range"><tr><td class="min"><input maxlength="25" name="date.min" size="21" type="text" value="2009-02-03 12:00:00 AM"></td><td> - </td><td class="max"><input maxlength="25" name="date.max" size="21" type="text" value="2001-07-08 11:59:59 PM"></td></tr><tr><td colspan="3"><span class="error">The min date cannot be later than the max date.</span></td></tr></table>', 'html 2 - date range');

is($field->xhtml, '<table class="date-range"><tr><td class="min"><input maxlength="25" name="date.min" size="21" type="text" value="2009-02-03 12:00:00 AM" /></td><td> - </td><td class="max"><input maxlength="25" name="date.max" size="21" type="text" value="2001-07-08 11:59:59 PM" /></td></tr><tr><td colspan="3"><span class="error">The min date cannot be later than the max date.</span></td></tr></table>', 'xhtml 1 - date range');

$field->field('min')->input_value('asdf');

ok(!$field->validate, 'validate 2 - date range');

is($field->html, '<table class="date-range"><tr><td class="min"><input class="error" maxlength="25" name="date.min" size="21" type="text" value="asdf"></td><td> - </td><td class="max"><input maxlength="25" name="date.max" size="21" type="text" value="2001-07-08 11:59:59 PM"></td></tr><tr><td colspan="3"><span class="error">Invalid date.</span></td></tr></table>', 'html 3 - date range');

is($field->xhtml, '<table class="date-range"><tr><td class="min"><input class="error" maxlength="25" name="date.min" size="21" type="text" value="asdf" /></td><td> - </td><td class="max"><input maxlength="25" name="date.max" size="21" type="text" value="2001-07-08 11:59:59 PM" /></td></tr><tr><td colspan="3"><span class="error">Invalid date.</span></td></tr></table>', 'xhtml 2 - date range');

$field->field('min')->input_value('3/6/1970');

ok($field->validate, 'validate 3 - date range');

$field->clear;

$field->field('min')->input_value('5/6/2004');

ok(!defined $field->internal_value, 'internal_value 6 - date range');

$field->field('max')->input_value('9/9/2005');

is($field->internal_value->[0]->strftime('%Y-%m-%d'), '2004-05-06', 'internal_value 7 - date range');

$field->field('min')->input_value('foo');

ok(!defined $field->internal_value, 'internal_value 7 - date range');

$field->input_value('2005-04-20 8pm to 1/7/2006 3:05 AM');

($min, $max) = $field->internal_value;

is($min->strftime('%Y-%m-%d %H:%M:%S'), "2005-04-20 20:00:00", 'internal_value 8 - date range');
is($max->strftime('%Y-%m-%d %H:%M:%S'), "2006-01-07 03:05:00", 'internal_value 9 - date range');

is($field->output_value, '2005-04-20 20:00:00#2006-01-07 03:05:00', 'output value 1 - date range');

$field->range_separator(' to ');

is($field->output_value, '2005-04-20 20:00:00 to 2006-01-07 03:05:00', 'range separator 1 - date range');

$field->range_separator_regex(qr(#|\s+(?:to|-)\s+));

$field->input_value('2005-04-20 7pm - 1/7/2006 3:06 AM');

is($field->output_value, '2005-04-20 19:00:00 to 2006-01-07 03:06:00', 'range separator regex 1 - date range');

package Rose::HTML::Form::Field::DateTime::Split::MDYHMS;

use strict;

use Rose::DateTime::Util();

use Rose::HTML::Form::Field::DateTime::Split::MonthDayYear;
use Rose::HTML::Form::Field::Time::Split::HourMinuteSecond;

use base 'Rose::HTML::Form::Field::DateTime::Split';

our $VERSION = '0.550';

sub build_field
{
  my($self) = shift;

  $self->add_fields
  (
    date => 'datetime split mdy',
    time => 'time split hms',
  );
}

sub decompose_value
{
  my($self, $value) = @_;

  return undef  unless(defined $value);

  my $date = $self->SUPER::inflate_value($value);

  unless($date)
  {
    no warnings;
    return
    {
      date  => substr($value, 0, 10) || '',
      time  => substr($value, 10) || '',
    }
  }

  my($mdy, $time) = Rose::DateTime::Util::format_date($date, '%m/%d/%Y', '%I:%M:%S %p');

  return
  {
    date => $mdy,
    time => $time,
  };
}

sub coalesce_value
{
  my($self) = shift;
  return join(' ', map { defined($_) ? $_ : '' } 
                   map { $self->field($_)->output_value }  qw(date time));
}

sub is_full
{
  my($self) = shift;

  my $count = grep { defined && length } 
              map { $self->field($_)->internal_value }  qw(date time);

  return $count == 2 ? 1 : 0;
}

sub deflate_value
{
  my($self, $date) = @_;
  return $self->input_value_filtered  unless($date);
  return Rose::DateTime::Util::format_date($date, '%m/%d/%Y %I:%M:%S %p');
}

sub html_field
{
  my($self) = shift;

  return '<span class="datetime">' .
         $self->field('date')->html_field . ' ' .
         $self->field('time')->html_field .
         '</span>';
}

sub xhtml_field
{
  my($self) = shift;

  return '<span class="datetime">' .
         $self->field('date')->xhtml_field . ' ' .
         $self->field('time')->xhtml_field .
         '</span>';
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::DateTime::Split::MDYHMS - Compound field for dates with separate text fields for month, day, year, hour, minute, and second, and a pop-up menu for AM/PM.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(
        label   => 'When',
        name    => 'when', 
        default => '12/31/2002 6:30 p.m.');

    print $field->field('time.minute')->internal_value; # "30"
    print $field->field('date.day')->internal_value;    # "31"

    print $field->internal_value; # "2002-12-31T18:30:00"
    print $field->output_value;   # "12/31/2002 06:30:00 PM"

    $field->input_value('blah');

    # "Could not parse date: blah"
    $field->validate or warn $field->error;

    $field->input_value('4/30/1980 1:23pm');

    $dt = $field->internal_value; # DateTime object

    print $dt->hour;     # 13
    print $dt->day_name; # Wednesday

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS> is a compound field for dates with separate text fields for month, day, year, hour, minute, and second, and a pop-up menu for AM/PM.

This class inherits (indirectly) from both L<Rose::HTML::Form::Field::DateTime> and L<Rose::HTML::Form::Field::Compound>.  This doesn't quite work out as expected without a bit of tweaking.  We'd like L<inflate_value()|Rose::HTML::Form::Field/inflate_value> and L<validate()|Rose::HTML::Form::Field/validate> methods to be inherited from L<Rose::HTML::Form::Field::DateTime>, but everything else to be inherited from L<Rose::HTML::Form::Field::Compound>.

To solve this problem, there's an intermediate class that imports the correct set of methods.  This class then inherits from the intermediate class.  This works, and isolates the tricky bits to a single intermediate class, but it also demonstrates the problems that can crop up when multiple inheritance is combined with a strong aversion to code duplication.

Inheritance shenanigans aside, this class is a good example of a compound field that includes other compound fields and also provides an "inflated" internal value (a L<DateTime> object).  This is the most complex custom field example in this distribution.  It does everything: nested compound fields, validation, inflate/deflate, and coalesce/decompose.

The date portion of the field is handled by a L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear> field, and the time portion is handled by a L<Rose::HTML::Form::Field::Time::Split::HourMinuteSecond> field.

It is important that this class (indirectly) inherits from L<Rose::HTML::Form::Field::Compound>. See the L<Rose::HTML::Form::Field::Compound> documentation for more information.

=head1 OBJECT METHODS

=over 4

=item B<date_parser [PARSER]>

Get or set the date parser object.  This object must include a C<parse_datetime()> method that takes a single string as an argument and returns a L<DateTime> object, or undef if parsing fails.

If the parser object has an C<error()> method, it will be called to set the error message after a failed parsing attempt.

The parser object defaults to L<Rose::DateTime::Parser-E<gt>new()|Rose::DateTime::Parser/new>.

=item B<time_zone [TZ]>

If the parser object has a L<time_zone()|/time_zone> method, this method simply calls it, passing all arguments.  Otherwise, undef is returned.

=back

=head1 SEE ALSO

Other examples of custom fields:

=over 4

=item L<Rose::HTML::Form::Field::Email>

A text field that only accepts valid email addresses.

=item L<Rose::HTML::Form::Field::Time>

Uses inflate/deflate to coerce input into a fixed format.

=item L<Rose::HTML::Form::Field::DateTime>

Uses inflate/deflate to convert input to a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Range>

A compound field whose internal value consists of more than one object.

=item L<Rose::HTML::Form::Field::PhoneNumber::US::Split>

A simple compound field that coalesces multiple subfields into a single value.

=item L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear>

A compound field that uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

package Rose::HTML::Form::Field::Time;

use strict;

use Rose::HTML::Object::Errors qw(:time);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.621';

__PACKAGE__->add_required_html_attr(
{
  size => 13,
});

sub inflate_value
{
  my($self, $time) = @_;

  no warnings; # undef time okay
  if($time =~ /^\s*(\d\d?)(?::(\d\d)(?::(\d\d))?)?\s*([ap]\.?m\.?)?\s*$/i)
  {
    my $hour = $1;
    my $min  = $2 || 0;
    my $sec  = $3 || 0;
    my $ampm = $4 || '';

    if($ampm)
    {
      $ampm = uc($ampm);
      $ampm =~ s/[^APM]//g;
    }

    unless($ampm)
    {
      if($hour >= 12)
      {
        $hour -= 12  if($hour > 12);
        $ampm = 'PM';
      }
      else { $ampm = 'AM' }
    }

    return sprintf("%02d:%02d:%02d $ampm", $hour, $min, $sec);
  }

  return $time;
}

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $time = $self->internal_value;

  return 1 unless ($time && $time =~ /\S/);

  unless($time =~ /^(\d\d):(\d\d):(\d\d) ([AP]M)$/)
  {
    $self->add_error_id(TIME_INVALID);
    return 0;
  }

  my $hour = $1;
  my $min  = $2 || 0;
  my $sec  = $3 || 0;
  my $ampm = $4 || '';

  if($hour > 12 && $ampm)
  {
    $self->add_error_id(TIME_INVALID_AMPM);
    return 0;
  }

  if($hour > 12 || $min > 59 || $sec > 59)
  {
    $self->add_error_id(TIME_INVALID);
    return 0;  
  }

  return 1;
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

TIME_INVALID = "Invalid time."
TIME_INVALID_AMPM = "AM/PM only valid with hours less than 12."

[% LOCALE de %]

TIME_INVALID = "Ungültige Zeit."
TIME_INVALID_AMPM = "AM und PM nur gültig mit Stunden kleiner 12."

[% LOCALE fr %]

TIME_INVALID         = "Heure invalide."
TIME_INVALID_AMPM    = "AM/PM n'est possible que si l'heure est plus petite que 12."

[% LOCALE bg %]

TIME_INVALID = "Невалиден час."
TIME_INVALID_AMPM = "Използването на AM/PM е разрешено за часове не по-големи от 12."

__END__

=head1 NAME

Rose::HTML::Form::Field::Time - Text field that accepts only valid times and coerces valid input into HH:MM:SS AM/PM format.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Time->new(
        label   => 'Time', 
        name    => 'time',
        default => '8am');

    print $field->internal_value; # "08:00:00 PM"

    $field->input_value('13:00:00 PM');

    # "AM/PM only valid with hours less than 12"
    $field->validate or warn $field->error;

    $field->input_value('blah');

    # "Invalid time"
    $field->validate or warn $field->error;

    $field->input_value('6:30 a.m.');

    print $field->internal_value; # "06:30:00 AM"

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Time> is a subclass of L<Rose::HTML::Form::Field::Text> that only allows values that are valid times, which it coerces into the form HH:MM:SS AM/PM.  It overrides the L<validate()|Rose::HTML::Form::Field/validate> and L<inflate_value()|Rose::HTML::Form::Field/inflate_value> methods of its parent class.

This is a good example of a custom field class that constrains the kinds of inputs that it accepts and coerces all valid input and output to a particular format.

=head1 SEE ALSO

Other examples of custom fields:

=over 4

=item L<Rose::HTML::Form::Field::Email>

A text field that only accepts valid email addresses.

=item L<Rose::HTML::Form::Field::DateTime>

Uses inflate/deflate to convert input to a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Range>

A compound field whose internal value consists of more than one object.

=item L<Rose::HTML::Form::Field::PhoneNumber::US::Split>

A simple compound field that coalesces multiple subfields into a single value.

=item L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear>

A compound field that uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS>

A compound field that includes other compound fields and uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

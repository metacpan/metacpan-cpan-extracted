package Rose::HTML::Form::Field::DateTime::EndDate;

use strict;

use base 'Rose::HTML::Form::Field::DateTime';

our $VERSION = '0.606';

sub inflate_value
{
  my($self) = shift;

  my $date = $self->SUPER::inflate_value(@_);

  return $date  unless(UNIVERSAL::isa($date, 'DateTime'));

  no warnings;
  # Pin to the last second of the day if no time is set
  $date->set(hour => 23, minute => 59, second => 59, nanosecond => 999999999)
    unless($self->input_value_filtered =~ /\d:\d|[ap]\.?m/i);

  return $date;
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::DateTime::EndDate - Text field for an "end date" in a date range.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::DateTime::EndDate->new(
        label   => 'Date',
        name    => 'date', 
        default => '12/31/2002');

    print $field->internal_value; # "2002-12-31T23:59:59"
    print $field->output_value;   # "2002-12-31 11:59:59 PM"

    $field->input_value('blah');

    # "Could not parse date: blah"
    $field->validate or warn $field->error;

    $field->input_value('4/30/1980 5:30 p.m.');

    $dt = $field->internal_value; # DateTime object

    print $dt->hour;     # 17
    print $dt->day_name; # Wednesday

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::DateTime::EndDate> is a subclass of L<Rose::HTML::Form::Field::DateTime> that pins the time to the very last nanosecond of the specified date (i.e., 23:59:59.999999999) if the time is left unspecified.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

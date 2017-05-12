package Rose::HTML::Form::Field::Date;

use strict;

use base 'Rose::HTML::Form::Field::DateTime';

our $VERSION = '0.606';

sub inflate_value
{
  my($self, $date) = @_;
  return undef  unless(ref $date || (defined $date && length $date));
  $date = $self->date_parser->parse_datetime($date);
  return $date  unless(UNIVERSAL::isa($date, 'DateTime'));
  $date->set(hour => 0, minute => 0, second => 0, nanosecond => 0);
  return $date;
}

sub init_output_format { '%Y-%m-%d' }

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Date - Text field that inflates valid dates into L<DateTime> objects.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Date->new(
        label   => 'Date',
        name    => 'date', 
        default => '12/31/2002');

    print $field->internal_value; # "2002-12-31T00:00:00"
    print $field->output_value;   # "2002-12-31"

    $field->input_value('blah');

    # "Could not parse date: blah"
    $field->validate or warn $field->error;

    $field->input_value('4/30/1980');

    $dt = $field->internal_value; # DateTime object

    print $dt->day_name; # Wednesday

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Date> is a subclass of L<Rose::HTML::Form::Field::DateTime> that handles dates, but not times.  (The time is always forced to be 00:00:00.)  Valid input is converted to the format "YYYY-MM-DD" on output.

See the L<Rose::HTML::Form::Field::DateTime> documetation for more information.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

package Rose::HTML::Form::Field::DateTime::StartDate;

use strict;

use base 'Rose::HTML::Form::Field::DateTime';

our $VERSION = '0.606';

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::DateTime::StartDate - Text field for a "start date" in a date range.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::DateTime::StartDate->new(
        label   => 'Date',
        name    => 'date', 
        default => '12/31/2002');

    print $field->internal_value; # "2002-12-31T00:00:00"
    print $field->output_value;   # "2002-12-31 00:00:00 PM"

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

L<Rose::HTML::Form::Field::DateTime::StartDate> is a subclass of L<Rose::HTML::Form::Field::DateTime> that pins the time to the very first moment of the specified date (i.e., 00:00:00.00000000) if the time is left unspecified.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

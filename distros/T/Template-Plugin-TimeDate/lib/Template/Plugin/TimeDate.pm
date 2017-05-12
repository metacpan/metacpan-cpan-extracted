package Template::Plugin::TimeDate;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Date::Parse qw();
use Date::Format qw();
use overload '""' => \&stringify;

###############################################################################
# Version number.
###############################################################################
our $VERSION = '1.02';

###############################################################################
# Derive ourselves from our base class.
###############################################################################
use Template::Plugin;
use base qw( Template::Plugin );

###############################################################################
# Subroutine:   new(string)
###############################################################################
# Creates a new TimeDate plug-in object, returning it to the caller.  An
# optional date/time string may be passed in, which is parsed automatically.
###############################################################################
sub new {
    my ($class, $context, $string) = @_;
    my $self = {};
    bless $self, $class;
    if ($string) {
        $self->parse( $string );
    }
    return $self;
}

###############################################################################
# Subroutine:   now
###############################################################################
# Sets the current time to "now", and returns it as "the number of seconds
# since the epoch".
###############################################################################
sub now {
    my $self = shift;
    $self->{'epoch'} = time();
    return $self->{'epoch'};
}

###############################################################################
# Subroutine:   epoch
###############################################################################
# Returns the currently set time as "the number of seconds since the epoch".
# If a date/time hasn't explicitly been parsed, we default to the current time.
###############################################################################
sub epoch {
    my $self = shift;
    unless ($self->{'epoch'}) {
        $self->now();
    }
    return $self->{'epoch'};
}

###############################################################################
# Subroutine:   parse(string, zone)
###############################################################################
# Parses the given date/time 'string' and sets that as the current time value
# for further operations.  An optional time 'zone' is used if there is no time
# zone information present in the provided date string.
###############################################################################
sub parse {
    my ($self, $string, $zone) = @_;
    $self->{'epoch'} = Date::Parse::str2time( $string, $zone );
    return $self;
}

###############################################################################
# Subroutine:   str2time(string, zone)
###############################################################################
# An alternate name for the 'parse' method above.
###############################################################################
*str2time = \&parse;

###############################################################################
# Subroutine:   format(format, zone)
###############################################################################
# Formats the current time value using the given strftime 'format', optionally
# converting it into the given time 'zone'.  If a date/time hasn't explicitly
# been parsed, we default to the current time.
#
# You may also refer to this method as 'time2str'; its original name from the
# 'Date::Format' module.
###############################################################################
sub format {
    my ($self, $format, $zone) = @_;
    return Date::Format::time2str( $format, $self->epoch(), $zone );
}

###############################################################################
# Subroutine:   time2str(format, zone)
###############################################################################
# An alternate name for the 'format' method above.
###############################################################################
*time2str = \&format;

###############################################################################
# Subroutine:   stringify
###############################################################################
# Stringifies the object, in ISO8601 format (%Y-%m-%d %H:%M:%S).
#
# This method is overloaded, so that simply turning the TimeDate object into a
# string will output it in ISO8601 format.
###############################################################################
sub stringify {
    my $self = shift;
    return $self->format( '%Y-%m-%d %H:%M:%S' );
}

1;

=head1 NAME

Template::Plugin::TimeDate - TT plugin to parse/format dates using TimeDate

=head1 SYNOPSIS

  [% USE TimeDate %]

  # get current time, as "seconds since the epoch"
  [% TimeDate.now %]

  # parse date string and show in default format (ISO8601)
  [% TimeDate.parse('2007-09-02 12:34:56 PDT') %]

  # parse date string with explicit time zone
  [% TimeDate.parse('2007-09-02 12:34:56', 'EDT') %]

  # get current time, with custom format
  [% TimeDate.format('%b %e %Y @ %l:%M %p') %]

  # parse/display
  [% USE mydate = TimeDate('2007-09-02 12:34:56 PDT') %]
  [% mydate.format('%b %e %Y @ %l:%M %p') %]

  # method chaining
  [% USE mydate = TimeDate %]
  [% mydate.parse('2007-09-02 12:34:56 PDT').format('%Y-%m-%d %H:%M:%S %z') %]

=head1 DESCRIPTION

C<Template::Plugin::TimeDate> is a TT plug-in that makes of the C<Date::Parse>
and C<Date::Format> modules from the C<TimeDate> distribution, to help deal
with parsing/formatting dates.

Why another date/time TT plug-in?  C<Template::Plugin::Date> doesn't handle
output in different timezones, and C<Template::Plugin::DateTime> didn't give me
a means of easily parsing dates before turning them into C<DateTime> objects.
I'd been using the C<Date::Parse> module elsewhere to parse dates, and so this
plug-in was built to help capture the parse/format cycle that I wanted to use in
my templates.

The plug-in should be loaded via the USE directive:

  [% USE TimeDate %]

This creates a plug-in object with the default name of 'TimeDate'.  An
alternate name can be specified such as:

  [% USE mydate = TimeDate %]

=head1 METHODS

=over

=item new(string)

Creates a new TimeDate plug-in object, returning it to the caller. An
optional date/time string may be passed in, which is parsed automatically. 

=item now

Sets the current time to "now", and returns it as "the number of seconds
since the epoch". 

=item epoch

Returns the currently set time as "the number of seconds since the epoch".
If a date/time hasn't explicitly been parsed, we default to the current
time. 

=item parse(string, zone)

Parses the given date/time C<string> and sets that as the current time
value for further operations. An optional time C<zone> is used if there is
no time zone information present in the provided date string. 

=item str2time(string, zone)

An alternate name for the C<parse> method above. 

=item format(format, zone)

Formats the current time value using the given strftime C<format>,
optionally converting it into the given time C<zone>. If a date/time hasn't
explicitly been parsed, we default to the current time. 

You may also refer to this method as C<time2str>; its original name from
the C<Date::Format> module. 

=item time2str(format, zone)

An alternate name for the C<format> method above. 

=item stringify

Stringifies the object, in ISO8601 format (%Y-%m-%d %H:%M:%S). 

This method is overloaded, so that simply turning the TimeDate object into
a string will output it in ISO8601 format. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<Date::Parse>,
L<Date::Format>,
L<Template>.

=cut

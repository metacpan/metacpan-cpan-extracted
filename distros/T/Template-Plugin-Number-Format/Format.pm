package Template::Plugin::Number::Format;

# ----------------------------------------------------------------------
#  Template::Plugin::Number::Format - Plugin/filter interface to Number::Format
#  Copyright (C) 2002-2015 Darren Chamberlain <darren@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION $DYNAMIC $AUTOLOAD);

$VERSION = '1.06';
$DYNAMIC = 1;

use Number::Format;
use base qw(Template::Plugin::Filter);

# ----------------------------------------------------------------------
# filter($text)
#
# The default filter is format_number, i.e., commify.
# ----------------------------------------------------------------------
sub filter {
    my ($self, $text, $args) = @_;
    $self->{ _NFO }->format_number($text, @$args);
}


# ----------------------------------------------------------------------
# init($config)
#
# Initialize the instance.  Creates a Number::Format object, which is
# used to create closures that implement the filters.
# ----------------------------------------------------------------------
sub init {
    my ($self, $config) = @_;
    my ($sub, $filter, $nfo);
    $nfo = Number::Format->new(%$config);
    
    $self->{ _DYNAMIC } = 1;
    $self->{ _NFO } = $nfo;

    # ------------------------------------------------------------------
    # This makes is dependant upon Number::Format not changing the 
    # Exporter interface it advertises, which is unlikely.
    #
    # It is likely that each of these subroutines should accept all
    # the configuration options of the constructor, and instantiate a
    # new Number::Format instance.  This is easier, for now.
    # ------------------------------------------------------------------
    for my $sub (@{$Number::Format::EXPORT_TAGS{"subs"}}) {
        my $filter = sub {
            my ($context, @args) = @_;
            return sub {
                my $text = shift;
                return $nfo->$sub($text, @args);
            };
        };
        $self->{ _CONTEXT }->define_filter($sub, $filter, 1);
    }

    return $self;
}

# ----------------------------------------------------------------------
# AUTOLOAD
#
# Catches method calls; so that the plugin can be used like you'd
# expect a plugin to work:
#
# [% USE nf = Number.Format; nf.format_number(num) %]
# ----------------------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;
   (my $autoload = $AUTOLOAD) =~ s/.*:://;

    return if $autoload eq 'DESTROY';

    $self->{ _NFO }->$autoload(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::Number::Format - Plugin/filter interface to Number::Format

=head1 SYNOPSIS

    [% USE Number.Format %]
    [% num | format_number %]

=head1 ABSTRACT

Template::Plugin::Number::Format makes the number-munging grooviness
of Number::Format available to your templates.  It is used like a
plugin, but installs filters into the current context.

=head1 DESCRIPTION

All filters created by Template::Plugin::Number::Format can be
configured by constructor options and options that can be passed to
individual filters.  See L<Number::Format/"METHODS"> for all the details.

=head2 Constructor Parameters

The USE line accepts the following parameters, all optional, which
define the default behavior for filters within the current Context:

=over 4

=item THOUSANDS_SEP

character inserted between groups of 3 digits

=item DECIMAL_POINT

character separating integer and fractional parts

=item MON_THOUSANDS_SEP

like THOUSANDS_SEP, but used for format_price

=item MON_DECIMAL_POINT

like DECIMAL_POINT, but used for format_price

=item INT_CURR_SYMBOL

character(s) denoting currency (see format_price())

=item DECIMAL_DIGITS

number of digits to the right of dec point (def 2)

=item DECIMAL_FILL

boolean; whether to add zeroes to fill out decimal

=item NEG_FORMAT

format to display negative numbers (def -x)

=item KILO_SUFFIX

suffix to add when format_bytes formats kilobytes

=item MEGA_SUFFIX

suffix to add when format_bytes formats megabytes

=item GIGA_SUFFIX

suffix to add when format_bytes formats gigabytes

=back

=head1 Using Template::Plugin::Number::Format

When you invoke:

    [% USE Number.Format(option = value) %]

the following filters are installed into the current Context:

=over 4

=item B<round($precision)>

Rounds the number to the specified precision.  If "$precision" is
omitted, the value of the "DECIMAL_DIGITS" parameter is used
(default value 2).

=item B<format_number($precision, $trailing_zeros)>

Formats a number by adding "THOUSANDS_SEP" between each set of 3
digits to the left of the decimal point, substituting "DECIMAL_POINT"
for the decimal point, and rounding to the specified precision using
"round()".  Note that "$precision" is a maximum precision specifier;
trailing zeroes will only appear in the output if "$trailing_zeroes"
is provided, or the parameter "DECIMAL_FILL" is set, with a value that
is true (not zero, undef, or the empty string).  If "$precision" is
omitted, the value of the "DECIMAL_DIGITS" parameter (default value
of 2) is used.

=item B<format_negative($picture)>

Formats a negative number.  Picture should be a string that contains
the letter "x" where the number should be inserted.  For example, for
standard negative numbers you might use "-x", while for
accounting purposes you might use "(x)".  If the specified number
begins with a - character, that will be removed before formatting, but
formatting will occur whether or not the number is negative.

=item B<format_picture($picture)>

Returns a string based on "$picture" with the "#" characters replaced
by digits from "$number".  If the length of the integer part of
$number is too large to fit, the "#" characters are replaced with
asterisks ("*") instead. 

=item B<format_price($precision)>

Returns a string containing "$number" formatted similarly to
"format_number()", except that the decimal portion may have trailing
zeroes added to make it be exactly "$precision" characters long, and
the currency string will be prefixed.

If the "INT_CURR_SYMBOL" attribute of the object is the empty string,
no currency will be added.

If "$precision" is not provided, the default of 2 will be used. 

=item B<format_bytes($precision)>

Returns a string containing "$number" formatted similarly to
"format_number()", except that if the number is over 1024, it will be
divided by 1024 and the value of KILO_SUFFIX appended to the end; or
if it is over 1048576 (1024*1024), it will be divided by 1048576 and
MEGA_SUFFIX appended to the end.  Negative values will result in an
error.

If "$precision" is not provided, the default of 2 will be used.

=item B<unformat_number>

Converts a string as returned by "format_number()", "format_price()",
or "format_picture()", and returns the corresponding value as a
numeric scalar.  Returns "undef" if the number does not contain any
digits.

=back

=head1 SEE ALSO

L<Template|Template>, L<Number::Format|Number::Format>

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>


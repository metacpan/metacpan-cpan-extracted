
package Palm::Progect::Date;
use strict;

=head1 NAME

Palm::Progect::Date - utility routines for converting dates

=head1 SYNOPSIS

    use Palm::Progect::Date;

    $date_due = parse_date('2038/12/31', 'yyyy/mm/dd');
    $date_due = parse_date('12-31-38', 'mm-dd-yy');

    my $formatted_date = format_date($time_in_unix_format, 'yyyy/mm/dd');

=head1 DESCRIPTION

These routines are used by the C<Palm::Progect::*> modules to parse and format
dates.

=cut


use Time::Local;
use Exporter;

use vars qw(@ISA @EXPORT);

@ISA = 'Exporter';

@EXPORT = qw(
    parse_date
    format_date
);

my %Date_Cache;

=head1 SUBROUTINES

=over 4

=item format_date($time, $date_format)

Given a time in Unix format (i.e. seconds since the epoch), return a string
representation of the date based on the given format:

    my $formatted_date = format_date($time_in_unix_format, 'yyyy/mm/dd');

    print format_date(0, 'yyyy-mm-dd'); # prints "1969-12-31"

The format can include the following symbols:

=over 4

=item yyyy

Four digit year

=item yy

Last two digits of year

=item mm

Month number

=item dd

Day number

=back

=cut

sub format_date {
    my ($time, $date_format) = @_;

    $time ||= 0;

    return $Date_Cache{$time . $date_format} if exists $Date_Cache{$time . $date_format};

    my ($day, $month, $year) = (localtime $time)[3,4,5];

    $day   = sprintf '%02d', $day;
    $month = sprintf '%02d', $month + 1;
    $year  = sprintf '%04d', $year  + 1900;
    my $shortyear = substr $year, -2, 2;

    my $date_string = $date_format;

    $date_string =~ s/dd/$day/gi;
    $date_string =~ s/mm/$month/gi;
    $date_string =~ s/yyyy/$year/gi;
    $date_string =~ s/yy/$shortyear/gi;

    return $Date_Cache{$time . $date_format} = $date_string;
}

=item parse_date($date_string, $date_format)

Attempt to parse C<$date_string> as a textual representation of a date,
using template supplied in C<$date_format>:

    my $time = parse_date('2038/10/24', 'yyyy/mm/dd')

    print parse_date('12-31, 1969', 'mm-dd, yyyy'); # prints 0

No attempt is made to guess the format of C<$date_string>; it is assumed
that you know its format.

C<$date_format> can include the following symbols:

=over 4

=item yyyy

Four digit year

=item yy

Last two digits of year

=item mm

Month number

=item dd

Day number

=back

=back

=cut

sub parse_date {
    my ($date_string, $date_format) = @_;


    my %values;

    # This parser is very convoluted.
    # For each token, we build a regexp
    # that matches it and all other tokens in the
    # format string, but we put parens around
    # the single token we're interested in
    # so we can capture its value.
    #
    # e.g. (assuming template of dd/mm/yy)
    #   first regex is  \d\d/\d\d/(\d\d)
    #   second regex is \d\d/(\d\d)/\d\d
    #   etc.
    #
    # So we build a regex for each token,
    # then run them all in sequence,
    # extracting one token for each regex
    #
    # We have to do 16 searches to construct
    # the regexes and then we also have to
    # search the date string 4 times.
    #
    # I'm sure there are better ways of
    # doing this.

    my @tokens = ('yyyy','mm','dd','yy');
    foreach my $token (@tokens) {
        my $format = $date_format;
        $format =~ s/$token/'(' . '\\d' x length($token) . ')'/ge;
        foreach my $token (@tokens) {
            $format =~ s/$token/'\\d' x length($token)/ge;
        }
        if ($date_string =~ /^$format$/) {
            $values{$token} = $1;
        }
    }

    my $day   = $values{'dd'};
    my $month = $values{'mm'};
    my $year  = $values{'yyyy'};

    # Y2K complient, but not Y2K+50 or Y2K-50 complient
    # no one's forcing you to use two-digit dates, you know.
    if ($values{'yy'} and $values{'yy'} < 50) {
        $values{'yy'} += 2000;
    }
    $year   ||= $values{'yy'};

    my $date;
    if ($day and $month and $year) {
        eval {
            $date = timelocal(0,0,0,$day,$month-1,$year);
        };
    }
    return $date;
}

1;

=head1 BUGS and CAVEATS

The two digit date format will fail for dates before 1950
or after 2049 :).

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut

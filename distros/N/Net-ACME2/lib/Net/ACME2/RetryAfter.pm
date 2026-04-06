package Net::ACME2::RetryAfter;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::RetryAfter - Parse RFC 7231 Retry-After header values

=head1 DESCRIPTION

This module parses the C<Retry-After> HTTP header (RFC 7231, section
7.1.3) into an integer number of seconds. The header value may be
either a non-negative integer (delay-seconds) or an HTTP-date.

This is used internally by L<Net::ACME2::Order> and
L<Net::ACME2::Authorization>.

=cut

use Time::Local ();

my %MON = (
    Jan => 0, Feb => 1, Mar => 2, Apr => 3,
    May => 4, Jun => 5, Jul => 6, Aug => 7,
    Sep => 8, Oct => 9, Nov => 10, Dec => 11,
);

=head1 FUNCTIONS

=head2 parse( $VALUE )

Parses a C<Retry-After> header value and returns the number of seconds
to wait (a non-negative integer), or C<undef> if C<$VALUE> is undefined
or cannot be parsed.

If C<$VALUE> is a non-negative integer, it is returned as-is.

If C<$VALUE> is an HTTP-date (IMF-fixdate, RFC 850, or asctime format),
the difference between that time and the current time is returned. If
the date is in the past, C<0> is returned.

=cut

sub parse {
    my ($value) = @_;

    return undef if !defined $value;

    # delay-seconds: a non-negative integer
    if ($value =~ m{\A([0-9]+)\z}) {
        return 0 + $1;
    }

    # Try to parse as HTTP-date
    my $epoch = _parse_http_date($value);

    return undef if !defined $epoch;

    my $delta = $epoch - time();

    return $delta > 0 ? int($delta) : 0;
}

# Parse the three HTTP-date formats defined in RFC 7231 section 7.1.1.1:
#   IMF-fixdate: Sun, 06 Nov 1994 08:49:37 GMT
#   RFC 850:     Sunday, 06-Nov-94 08:49:37 GMT
#   asctime:     Sun Nov  6 08:49:37 1994
sub _parse_http_date {
    my ($str) = @_;

    my ($day, $mon_name, $year, $hour, $min, $sec);

    if ($str =~ m{\A\w+, \s* (\d{2}) \s (\w{3}) \s (\d{4}) \s (\d{2}):(\d{2}):(\d{2}) \s GMT\z}x) {
        # IMF-fixdate
        ($day, $mon_name, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    }
    elsif ($str =~ m{\A\w+, \s* (\d{2})-(\w{3})-(\d{2}) \s (\d{2}):(\d{2}):(\d{2}) \s GMT\z}x) {
        # RFC 850 (2-digit year)
        ($day, $mon_name, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
        $year += $year < 70 ? 2000 : 1900;
    }
    elsif ($str =~ m{\A\w+ \s+ (\w{3}) \s+ (\d{1,2}) \s (\d{2}):(\d{2}):(\d{2}) \s (\d{4})\z}x) {
        # asctime
        ($mon_name, $day, $hour, $min, $sec, $year) = ($1, $2, $3, $4, $5, $6);
    }
    else {
        return undef;
    }

    my $mon = $MON{$mon_name};

    return undef if !defined $mon;

    return eval { Time::Local::timegm($sec, $min, $hour, $day, $mon, $year) };
}

1;

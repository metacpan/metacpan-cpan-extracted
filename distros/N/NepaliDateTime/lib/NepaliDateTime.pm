package NepaliDateTime;

use strict;
use warnings;
use utf8;

our $VERSION = '0.02';

=encoding utf8

=head1 NAME

NepaliDateTime - Bikram Sambat (B.S.) date and datetime for Perl

=head1 SYNOPSIS

    use NepaliDateTime::Date;
    use NepaliDateTime::DateTime;

    # Today in BS
    my $today = NepaliDateTime::Date->today();
    printf "Today (BS): %s\n", $today->isoformat();

    # Construct a BS date
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    printf "Weekday: %s\n", $d->day_name();

    # Convert AD → BS
    use Time::Piece;
    my $ad = Time::Piece->strptime('2024-07-15', '%Y-%m-%d');
    my $bs = NepaliDateTime::Date->from_ad($ad->year, $ad->mon, $ad->mday);
    printf "BS: %s\n", $bs;

    # Convert BS → AD
    my ($y, $m, $d2) = $bs->to_ad();
    printf "AD: %04d-%02d-%02d\n", $y, $m, $d2;

    # Arithmetic
    my $tomorrow = $d->add_days(1);
    my $delta    = $tomorrow - $d;    # days difference

    # Formatting
    print $d->strftime('%B %Y'), "\n";          # "Asar 2081"
    print $d->strftime_np('%N %K'), "\n";       # Devanagari month + year
    print $d->format_devanagari(), "\n";        # full Devanagari

    # Fiscal year (Nepal: Shrawan–Ashadh)
    printf "Fiscal year: %d/%d\n", $d->fiscal_year();

    # Datetime
    my $now = NepaliDateTime::DateTime->now();
    printf "Now (BS): %s\n", $now->isoformat();

=head1 DESCRIPTION

NepaliDateTime implements Bikram Sambat (B.S.) date handling for Perl,
mirroring the Python C<nepali_datetime> library and extending it with
additional convenience features.

Supported BS date range: 1975-01-01 to 2100-12-30.

The reference anchor is:
  AD 1918-04-13  ≡  BS 1975-01-01

Nepal Standard Time is UTC+05:45.

=head1 MODULES

=over 4

=item L<NepaliDateTime::Date>     – BS date object

=item L<NepaliDateTime::DateTime> – BS datetime object (adds HH:MM:SS)

=back

=head1 AUTHOR

Generated for Bikram Sambat date arithmetic in Perl.

=head1 LICENSE

MIT

=cut

1;

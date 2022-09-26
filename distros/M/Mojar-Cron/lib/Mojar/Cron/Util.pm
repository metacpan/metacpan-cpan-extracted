package Mojar::Cron::Util;
use Mojo::Base -strict;

our $VERSION = 0.051;

use Carp 'croak';
use Exporter 'import';
use POSIX qw(mktime strftime);
use Time::Local 'timegm';

our @EXPORT_OK = qw(
  time_to_zero zero_to_time cron_to_zero zero_to_cron life_to_zero zero_to_life
  balance normalise_utc normalise_local date_today date_next date_previous
  date_dow utc_to_ts local_to_ts ts_to_utc ts_to_local local_to_utc utc_to_local
  tz_offset
);

# Public functions

sub time_to_zero { @_[0..2], $_[3] - 1, @_[4..$#_] }
sub zero_to_time { @_[0..2], $_[3] + 1, @_[4..$#_] }

sub cron_to_zero { @_[0..2], $_[3] - 1, $_[4] - 1, @_[5..$#_] }
sub zero_to_cron { @_[0..2], $_[3] + 1, $_[4] + 1, @_[5..$#_] }

sub life_to_zero { @_[0..2], $_[3] - 1, $_[4] - 1, $_[5] - 1900, @_[6..$#_] }
sub zero_to_life { @_[0..2], $_[3] + 1, $_[4] + 1, $_[5] + 1900, @_[6..$#_] }

sub balance {
  my @parts = @_;
  my @Max = (59, 59, 23, undef, 11);
  # Bring values within range for sec, min, hour, month (zero-based)
  for (0,1,2,4) {
    $parts[$_] += $Max[$_] + 1, --$parts[$_ + 1] while $parts[$_] < 0;
    $parts[$_] -= $Max[$_] + 1, ++$parts[$_ + 1] while $parts[$_] > $Max[$_];
  }
  return @parts;
}

sub normalise_utc {
  my @parts = balance @_;
  my $days = $parts[3] - 1;  # could be negative
  my $ts = timegm @parts[0..2], 1, @parts[4..$#parts];  # first of the month
  $ts += $days * 24 * 60 * 60;
  return gmtime $ts;
}

sub normalise_local {
  my @parts = balance @_;
  my $days = 0;
  if ($parts[3] < 1 or 28 < $parts[3] && $parts[4] == 1 or 30 < $parts[3]) {
    $days = $parts[3] - 1;  # possibly negative
    $parts[3] = 1;
  }
  my $ts = mktime @parts;
  $ts += $days * 24 * 60 * 60;
  return localtime $ts;
}

sub date_today { strftime '%Y-%m-%d', localtime }

sub date_next {
  strftime '%Y-%m-%d', 0,0,0, $3 + 1, $2 - 1, $1 - 1900
    if shift =~ /^(\d{4})-(\d{2})-(\d{2})\b/;
}

sub date_previous {
  strftime '%Y-%m-%d', 0,0,0, $3 - 1, $2 - 1, $1 - 1900
    if shift =~ /^(\d{4})-(\d{2})-(\d{2})\b/;
}

sub date_dow {
  strftime '%u', 0,0,0, $3 + 1, $2 - 1, $1 - 1900
    if shift =~ /^(\d{4})-(\d{2})-(\d{2})\b/;
}

sub utc_to_ts    { timegm @_ }
sub local_to_ts  { mktime @_ }

sub ts_to_utc    { gmtime $_[0] }
sub ts_to_local  { localtime $_[0] }

sub local_to_utc { gmtime mktime @_ }
sub utc_to_local { localtime timegm @_ }

my %UnitFactor = (
  S => 1,
  M => 60,
  H => 60 * 60,
  d => 60 * 60 * 24,
  w => 60 * 60 * 24 * 7,
  m => 60 * 60 * 24 * 30,
  y => 60 * 60 * 24 * 365
);

sub str_to_delta {
  my ($str) = @_;
  return 0 unless $str;
  return $str if $str =~ /^[-+]?\d+S?$/;
  return $1 * $UnitFactor{$2} if $str =~ /^([-+]?\d+)([MHdwmy])$/;
  croak qq{Failed to interpret time period ($str)};
}

sub tz_offset {
  my $now = shift // time;
  my ($lm, $lh, $ly, $ld) = (localtime $now)[1, 2, 5, 7];
  my ($um, $uh, $uy, $ud) = (gmtime $now)[1, 2, 5, 7];
  my $min = $lm - $um + 60 * ($lh - $uh) + 60 * 24 * ($ly - $uy or $ld - $ud);
  return _format_offset($min);
}

# Private function

# This is simply to aid unit testing
sub _format_offset {
  my $min = shift;
  my $sign = $min < 0 ? '-' : '+';
  $min = abs $min;
  my $hr = int(($min + 0.5) / 60);
  $min = $min - 60 * $hr;
  return sprintf '%s%02u%02u', $sign, abs($hr), abs($min);
}

1;
__END__

=head1 NAME

Mojar::Cron::Util - Time utility functions

=head1 SYNOPSIS

  use Mojar::Cron::Util 'date_next';

=head1 DESCRIPTION

Utility functions for dates and times.

=head1 FUNCTIONS

=head2 time_to_zero

  ($S, $M, $H, $d, $m, $y) = time_to_zero($S, $M, $H, $d, $m, $y);

Converts time representations to zero-based datetimes.  So day 1 translates to
0, while months and years are left 0-based.

=head2 zero_to_time

  ($S, $M, $H, $d, $m, $y) = zero_to_time($S, $M, $H, $d, $m, $y);

Converts zero-based datetimes to time representations.  So day 0 translates to
1, but months and years are left 0-based.

=head2 cron_to_zero

  ($S, $M, $H, $d, $m, $y) = cron_to_zero($S, $M, $H, $d, $m, $y);

Converts cron representations to zero-based datetimes.  So day 1 translates to
0, month 1 translates to 0 (January), while years are left 0-based.

=head2 zero_to_cron

  ($S, $M, $H, $d, $m, $y) = zero_to_cron($S, $M, $H, $d, $m, $y);

Converts zero-based datetimes to cron representations.  So day 0 translates to
1, month 0 translates to 1 (January), but years are left 0-based.

=head2 life_to_zero

  ($S, $M, $H, $d, $m, $y) = life_to_zero($S, $M, $H, $d, $m, $y);

Converts real-life representations to zero-based datetimes.  So day 1 translates
to 0, month 1 translates to 0 (January), and year 1900 translates to 0.

=head2 zero_to_life

  ($S, $M, $H, $d, $m, $y) = zero_to_life($S, $M, $H, $d, $m, $y);

Converts zero-based datetimes to real-life representations.  So day 0 translates
to 1, month 0 translates to 1 (January), and year 0 translates to 1900.

=head2 balance

  ($S, $M, $H, $d, $m, $y) = balance($S, $M, $H, $d, $m, $y);

Balance-out any simple-minded anomalies such as seconds being less than 0 or
greater than 59, or days being less than 0 or greater than 31.  This lets you
make crude adjustments, such as adding 30 mins, and then letting this function
balance it back into the realms of normality.  Note that it takes care of
everything except the length of months, and so is mainly only used by the two
normalise functions which will handle that.

=head2 normalise_utc

  ($S, $M, $H, $d, $m, $y) = normalise_utc($S, $M, $H, $d, $m, $y);

Normalises a UTC datetime to a valid value.  For example, 31 April translates to
1 May.

=head2 normalise_local

  ($S, $M, $H, $d, $m, $y) = normalise_local($S, $M, $H, $d, $m, $y);

Normalises a local datetime to a valid value.  For example, 31 April translates
to 1 May.

=head2 date_today

  $today = date_today();  # yyyy-mm-dd

Provides today's date, using the local (system) clock.

=head2 date_previous

  $previous = date_previous('2015-03-01');
  $yesterday = date_previous(date_today());

Provides the previous date.

=head2 date_next

  $next = date_next('2015-02-28');
  $tomorrow = date_next(date_today());

Provides the following date.

=head2 utc_to_ts

=head2 local_to_ts

=head2 ts_to_utc

=head2 ts_to_local

=head2 local_to_utc

=head2 utc_to_local

=head2 str_to_delta

=head2 tz_offset

  $offset = tz_offset;
  $offset = tz_offset($epoch);

Provides the numeric timezone offset, taking daylight saving into account.  It
is more portable than

  POSIX::strftime('%z')

as it works on non-nix platforms such as Windows.  This is required by some date
formats, such as in SMTP.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012--2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojar::Util>, L<POSIX>.

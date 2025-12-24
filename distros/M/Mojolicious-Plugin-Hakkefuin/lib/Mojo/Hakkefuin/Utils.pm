package Mojo::Hakkefuin::Utils;
use Mojo::Base -base;

use Mojo::Date;
use String::Random;

sub gen_cookie {
  my ($self, $num) = @_;
  $num //= 3;
  state $random = String::Random->new;
  $random->randpattern('CnCCcCCnCn' x $num);
}

sub sql_datetime {
  my ($self, $time_plus) = @_;
  $time_plus //= 0;
  my $epoch     = time + $time_plus;
  my $to_get_dt = Mojo::Date->new($epoch)->to_datetime;
  $to_get_dt =~ qr/^([0-9\-]+)\w([0-9\:]+)(.*)/;
  return $1 . ' ' . $2;
}

sub time_convert {
  my ($self, $abbr) = @_;

  # Reset shortening time
  $abbr //= '1h';
  $abbr =~ qr/^([\d.]+)(\w)/;

  # Set standard of time units
  my $minute = 60;
  my $hour   = 60 * 60;
  my $day    = 24 * $hour;
  my $week   = 7 * $day;
  my $month  = 30 * $day;
  my $year   = 12 * $month;

  # Calculate by time units.
  my $identifier;
  $identifier = int $1 * 1   if $2 eq 's';
  $identifier = $1 * $minute if $2 eq 'm';
  $identifier = $1 * $hour   if $2 eq 'h';
  $identifier = $1 * $day    if $2 eq 'd';
  $identifier = $1 * $week   if $2 eq 'w';
  $identifier = $1 * $month  if $2 eq 'M';
  $identifier = $1 * $year   if $2 eq 'y';
  return $identifier;
}

1;

=encoding utf8

=head1 NAME

Mojo::Hakkefuin::Utils - Utilities

=head1 SYNOPSIS

  use Mojo::Hakkefuin::Utils;
  
  my $utils = Mojo::Hakkefuin::Utils->new;
  
  # to generate cookie
  my $cookie = $utils->gen_cookie;
  
  # to generate sql time
  my $sql_time = $utils->sql_datetime;
  
  # to generate time by the abbreviation
  my $time = $utils->time_convert('1d');

=head1 DESCRIPTION

General utilities which used on Backend and plugin class.

=head1 METHODS

L<Mojo::Hakkefuin::Utils> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 gen_cookie

  my $cookie = $utils->gen_cookie;
  my $cookie = $utils->gen_cookie(3);
  
This method only generate cookie login.

=head2 sql_datetime

  my $sql_time = $utils->sql_datetime;
  my $sql_time = $utils->sql_datetime(60 * 60);
  
This method only generate datetime.

=head2 time_convert

  # To get 1 hour in units of seconds.
  my $time = $utils->time_convert;
  
  # time specified by the abbreviation
  my $time = $utils->time_convert('1d');
  
Abbreviation of time :

  s = seconds.
  m = minutes
  h = hours
  d = days
  w = weeks
  M = months
  y = years
  
=head1 SEE ALSO

=over 1

=item * L<Mojolicious::Plugin::Hakkefuin>

=item * L<Mojo::Hakkefuin>

=item * L<Mojo::mysql>

=item * L<Mojo::Pg>

=item * L<Mojo::SQLite>

=item * L<Mojolicious::Guides>

=item * L<https://mojolicious.org>

=back

=cut

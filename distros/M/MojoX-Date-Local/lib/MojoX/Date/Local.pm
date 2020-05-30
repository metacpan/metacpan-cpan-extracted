package MojoX::Date::Local;
use Mojo::Date -base;

our $VERSION = "0.04";

use POSIX qw(strftime);

our $DEFAULT_FORMAT = '%a, %d %b %Y %H:%M:%S %Z';

sub to_datetime {

  # RFC 3339 (1994-11-06T00:49:37-08:00)
  my $epoch = shift->epoch;
  my @time  = localtime $epoch;
  my $fmt
    = $epoch =~ m{ (\.\d+) $ }x
    ? '%Y-%m-%dT%H:%M:%S' . $1 . '%z'
    : '%Y-%m-%dT%H:%M:%S%z';
  my $timestamp = strftime $fmt, @time;

  # %z is '+HHMM', but RFC-3339 wants '+HH:MM'
  $timestamp =~ s{ (\d\d)(\d\d) $}{$1:$2}x;
  return $timestamp;
}

sub format {
  my @time = localtime shift->epoch;
  my $fmt  = shift || $DEFAULT_FORMAT;
  return strftime $fmt, @time;
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Date::Local - Mojo::Date, but in my timezone and with custom formats

=head1 SYNOPSIS

  use MojoX::Date::Local;

  my $now = MojoX::Date::Local->new;
  say $now->to_datetime;        # => 2020-05-27T17:39:43-08:00
  say $now->format;             # => Wed, 27 May 2020 17:39:43 PDT
  say $now->format('%H:%M:%S'); # => 17:39:43

=head1 DESCRIPTION

This module lets you use L<Mojo::Date>'s concise date / time functionality within the context of your own time zone.
That's mainly useful when logging to the console with a custom L<Mojo::Log> format:

  use Mojo::Log;
  use MojoX::Date::Local;

  my $logger = Mojo::Log->new;

  $logger->format(
    sub ($time, $level, @lines) {
      my ($time, $level, @lines) = @_;
      my $timestamp = MojoX::Date::Local->new($time)->to_datetime;
      my $prefix    = "[$timestamp] [$level]";
      my $message   = join "\n", @lines, "";
      return "$prefix $message";
    }
  );


=head1 METHODS

A MojoX::Date::Local provides L<Mojo::Date>'s methods, with a couple changes.

=head2 to_datetime

Render local date+time in L<RFC 3339|http://tools.ietf.org/html/rfc3339> format, with timezone offset.
If the time has fractional seconds, those will be included in the output.

=head2 format($fmt)

Return presumably locale-appropriate formatting of local date+time per L<POSIX::strftime>'s formatting rules.
C<'%a, %d %b %Y %H:%M:%S %Z'> is used if C<$fmt> string is not provided. This produces a string similar to but
not quite compliant with L<RFC 7231|https://tools.ietf.org/html/rfc7231#section-7.1.1.1>, which makes no
allowances for localization. But it's still nice to have when displaying dates informally.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Date>, L<POSIX>

=head1 LICENSE

Copyright (C) Brian Wisti.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Brian Wisti E<lt>brianwisti@pobox.comE<gt>

=cut

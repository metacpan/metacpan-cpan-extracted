package Mojo::Log::Role::Color;
use Mojo::Base -role;

use Term::ANSIColor ();

our $VERSION = '0.04';

our %COLORS = (
  debug => ['cyan'],
  error => ['red'],
  fatal => ['white on_red'],
  info  => ['green'],
  warn  => ['yellow'],
);

has colored => sub { $ENV{MOJO_LOG_COLORS} // -t shift->handle };

around format => sub {
  my ($next, $self) = (shift, shift);

  # set
  return $next->($self, @_) if @_;

  # get
  my $formatter = $next->($self);
  return $formatter unless $self->colored;

  return sub {
    my $level   = $_[1];
    my $message = $formatter->(@_);
    my $newline = $message =~ s!(\r?\n)$!! ? $1 : '';
    return Term::ANSIColor::colored($COLORS{$level} || $COLORS{debug}, $message)
      . $newline;
  };
};

sub import {
  my $class = shift;
  return unless my @flags = @_;

  my $caller = caller;
  while (my $flag = shift @flags) {
    if ($flag eq '-func') {
      require Mojo::Log;
      my $fqn = shift @flags || 'l';
      $fqn = "${caller}::$fqn" unless $fqn =~ m!::!;
      no strict 'refs';
      *$fqn = \&_l;
    }
  }
}

sub _f {
  my $format = shift;

  state $f = {
    ymd => sub {
      my ($d, $m, $y) = (localtime $_[0])[3, 4, 5];
      sprintf sprintf '%04d-%02d-%02d', $y + 1900, $m + 1, $d;
    },
    hms => sub {
      my ($s, $m, $h) = localtime $_[0];
      sprintf '%02d:%02d:%08.5f', $h, $m, "$s." . ((split /\./, $_[0])[1] // 0);
    },
    level => sub { $_[1] },
    m     => sub { join "\n", @{$_[2]}, '' },
    pid   => sub {$$},
  };

  my $re = join '|', keys %$f;
  $re = qr{%($re)};

  return sub {
    my ($str, $time, $level) = ($format, shift, shift);
    $str =~ s!$re!{$f->{$1}($time, $level, \@_)}!ge;
    return $str;
  };
}

sub _l {
  my ($level, $format, @args) = @_;
  state $log
    = Mojo::Log->with_roles('+Color')->new->colored($ENV{MOJO_LOG_COLORS} // 1)
    ->format(_f($ENV{MOJO_LOG_FORMAT} || '[%hms] %m'));
  return $log unless $level;
  return $log->$level(@args
    ? sprintf $format, map { $_ // 'undef' } @args
    : $format);
}

1;

=encoding utf8

=head1 NAME

Mojo::Log::Role::Color - Add colors to your mojo logs

=head1 SYNOPSIS

  use Mojo::Log;
  my $log = Mojo::Log->with_roles("+Color")->new;
  $log->info("FYI: it happened again");

=head1 DESCRIPTION

L<Mojo::Log::Role::Color> is a role you can apply to your L<Mojo::Log> to get
colored log messages when running your application in interactive mode.

It is also possible to set the C<MOJO_LOG_COLORS> environment variable to force
colored output.

The coloring is based on the log level:

  debug: cyan text
  info:  green text
  warn:  yellow text
  error: red text
  fatal: white text on red background

The colors can be customized by changing C<%Mojo::Log::Role::Color::COLORS>,
though this is not officially supported, and may break in a future release.

=head1 EXPORTED FUNCTIONS

  use Mojo::Log::Role::Color -func;
  l error => "too %s", "cool";

  use Mojo::Log::Role::Color -func => 'main::DEBUG';
  main::DEBUG error => "too %s", "cool";

  $ MOJO_LOG_FORMAT="%hms %m" PERL5OPT="-MMojo::Log::Role::Color=-func" perl -le'::l error => "bad"'
  $ MOJO_LOG_FORMAT="%ymdT%hms [%pid] [%level] %m" PERL5OPT="-MMojo::Log::Role::Color=-func" prove -vl t/test.t

It is possible to import a logging function that provides a quick and dirty
logging interface.

The C<-func> switch might change without warning. It's only supposed to be used
for quick debug output.

=head1 ATTRIBUTES

=head2 colored

  $bool = $log->colored;
  $log = $log->colored(1);

Check if colored output is enabled, or force it to a given state.  Defaults to
C<MOJO_LOG_COLORS> environment variable, or will be set to "1" if
L<Mojo::Log/handle> is attached to a terminal.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Log>.

=cut

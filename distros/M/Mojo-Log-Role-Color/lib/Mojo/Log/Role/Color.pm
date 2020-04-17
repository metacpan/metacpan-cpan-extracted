package Mojo::Log::Role::Color;
use Mojo::Base -role;

use Term::ANSIColor ();

our $VERSION = '0.02';

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

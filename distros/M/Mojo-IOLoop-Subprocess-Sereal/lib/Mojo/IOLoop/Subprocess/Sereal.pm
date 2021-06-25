package Mojo::IOLoop::Subprocess::Sereal;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '1.002';

our @EXPORT = '$_subprocess';

our $_subprocess = sub {
  my $subprocess = shift->subprocess
    ->with_roles('Mojo::IOLoop::Subprocess::Role::Sereal')->with_sereal;
  return @_ ? $subprocess->run(@_) : $subprocess;
};

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::Subprocess::Sereal - Subprocesses with Sereal

=head1 SYNOPSIS

  use Mojo::IOLoop::Subprocess::Sereal;

  # Operation that would block the event loop for 5 seconds
  my $subprocess = Mojo::IOLoop->$_subprocess(
    sub {
      my $subprocess = shift;
      sleep 5;
      return '♥', 'Mojolicious';
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say "I $results[0] $results[1]!";
    }
  );

  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

L<Mojo::IOLoop::Subprocess::Sereal> provides a L</"$_subprocess"> method which
works as a drop-in replacement for L<Mojo::IOLoop/"subprocess"> while using
L<Sereal> for data serialization. L<Sereal> is faster than L<Storable> and
supports serialization of more reference types such as C<Regexp>. The
L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> is supported to control
serialization of blessed objects.

See L<Mojo::IOLoop::Subprocess::Role::Sereal> for a role to apply L<Sereal>
data serialization to any L<Mojo::IOLoop::Subprocess>.

=head1 EXPORTS

L<Mojo::IOLoop::Subprocess::Sereal> exports the following variable by default.

=head2 $_subprocess

  my $subprocess = Mojo::IOLoop->$_subprocess(sub {...}, sub {...});
  my $subprocess = Mojo::IOLoop->$_subprocess;
  my $subprocess = $loop->$_subprocess(sub {...}, sub {...});

Build L<Mojo::IOLoop::Subprocess> object to perform computationally expensive
operations in subprocesses, without blocking the event loop. Composes and calls
L<Mojo::IOLoop::Subprocess::Role::Sereal/"with_sereal"> to use L<Sereal> for
data serialization. If arguments are provided, they will be used to call
L<Mojo::IOLoop::Subprocess/"run">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::IOLoop>, L<Mojo::IOLoop::Subprocess::Role::Sereal>, L<Sereal>

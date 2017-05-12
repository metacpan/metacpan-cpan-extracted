package Mojo::IOLoop::Subprocess::Sereal;

use strict;
use warnings;
use Exporter 'import';
use Mojo::IOLoop::Subprocess;
use Scalar::Util 'weaken';
use Sereal::Decoder 'sereal_decode_with_object';
use Sereal::Encoder 'sereal_encode_with_object';

our $VERSION = '0.005';

our @EXPORT = '$_subprocess';

my $deserializer = Sereal::Decoder->new;
my $deserialize = sub { sereal_decode_with_object $deserializer, $_[0] };

my $serializer = Sereal::Encoder->new({freeze_callbacks => 1});
my $serialize = sub { sereal_encode_with_object $serializer, $_[0] };

our $_subprocess = sub {
  my $ioloop = shift;
  my $subprocess = Mojo::IOLoop::Subprocess
    ->new(deserialize => $deserialize, serialize => $serialize);
  weaken $subprocess->ioloop(ref $ioloop ? $ioloop : $ioloop->singleton)->{ioloop};
  return $subprocess->run(@_);
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

=head1 EXPORTS

L<Mojo::IOLoop::Subprocess::Sereal> exports the following variable by default.

=head2 $_subprocess

  my $subprocess = Mojo::IOLoop->$_subprocess(sub {...}, sub {...});
  my $subprocess = $loop->$_subprocess(sub {...}, sub {...});

Build L<Mojo::IOLoop::Subprocess> object to perform computationally expensive
operations in subprocesses, without blocking the event loop. Sets
L<Mojo::IOLoop::Subprocess/"deserialize"> and
L<Mojo::IOLoop::Subprocess/"serialize"> to callbacks that use L<Sereal> for
data serialization. Arguments will be passed along to
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

L<Mojo::IOLoop>, L<Sereal>

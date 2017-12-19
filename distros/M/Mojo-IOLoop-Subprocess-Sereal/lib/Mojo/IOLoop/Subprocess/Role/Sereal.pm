package Mojo::IOLoop::Subprocess::Role::Sereal;

use Role::Tiny;
use Sereal::Decoder;
use Sereal::Encoder;

our $VERSION = '1.000';

requires qw(deserialize serialize);

my $deserializer = Sereal::Decoder->new;
my $deserialize = sub { Sereal::Decoder::sereal_decode_with_object($deserializer, $_[0]) };

my $serializer = Sereal::Encoder->new({freeze_callbacks => 1});
my $serialize = sub { Sereal::Encoder::sereal_encode_with_object($serializer, $_[0]) };

sub with_sereal { shift->deserialize($deserialize)->serialize($serialize) }

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::Subprocess::Role::Sereal - Subprocesses with Sereal

=head1 SYNOPSIS

  use Mojo::IOLoop;

  # Operation that would block the event loop for 5 seconds
  my $subprocess = Mojo::IOLoop->subprocess->with_roles('+Sereal')->with_sereal->run(
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

L<Mojo::IOLoop::Subprocess::Role::Sereal> provides a L</"with_sereal"> method
for L<Mojo::IOLoop::Subprocess> objects that will update its C<serialize> and
C<deserialize> attributes to use L<Sereal> for data serialization. L<Sereal> is
faster than L<Storable> and supports serialization of more reference types such
as C<Regexp>. The L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> is
supported to control serialization of blessed objects.

See L<Mojo::IOLoop::Subprocess::Sereal> for a method to retrieve a subprocess
object using L<Sereal> directly from L<Mojo::IOLoop>.

=head1 METHODS

L<Mojo::IOLoop::Subprocess::Role::Sereal> composes the following methods.

=head2 with_sereal

  $subprocess = $subprocess->with_sereal;

Set L<Mojo::IOLoop::Subprocess/"deserialize"> and
L<Mojo::IOLoop::Subprocess/"serialize"> to callbacks that use L<Sereal> for
data serialization.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::IOLoop::Subprocess>, L<Mojo::IOLoop::Subprocess::Sereal>, L<Sereal>

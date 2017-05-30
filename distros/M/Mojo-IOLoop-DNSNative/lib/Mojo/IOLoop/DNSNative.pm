package Mojo::IOLoop::DNSNative;
$Mojo::IOLoop::DNSNative::VERSION = '0.001';
# ABSTRACT: Async native DNS lookup
use Mojo::Base -base;

use List::Util qw/ uniq /;
use Mojo::IOLoop;
use Net::DNS::Native;
use Socket qw/ getnameinfo NI_NUMERICHOST NIx_NOSERV /;

has NDN =>
  sub { state $NDN = Net::DNS::Native->new(pool => 5, extra_thread => 1) };
has reactor => sub { Mojo::IOLoop->singleton->reactor };
has timeout => 10;

sub lookup {
  my ($self, $address, $cb) = @_;

  my $reactor = $self->reactor;
  my $ndn     = $self->NDN;

  my $handle = $ndn->getaddrinfo($address, undef);
  my $tid;
  if (my $timeout = $self->timeout) {
    $tid = $reactor->timer(
      $timeout,
      sub {
        $ndn->timedout($handle);
        $reactor->remove($handle);
        $cb->('DNS lookup timed out');
      }
    );
  }
  $reactor->io(
    $handle => sub {
      my $reactor = shift;
      $reactor->remove($handle);
      $reactor->remove($tid) if defined $tid;
      my ($err, @res) = $ndn->get_result($handle);

      $cb->(
        $err,
        uniq map { (getnameinfo($_->{addr}, NI_NUMERICHOST, NIx_NOSERV))[1] }
          @res
      );
    }
  )->watch($handle, 1, 0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::IOLoop::DNSNative - Async native DNS lookup

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use feature 'say';
  use Mojo::IOLoop;
  use Mojo::IOLoop::DNSNative;

  my $loop = Mojo::IOLoop->new;
  my $dns = Mojo::IOLoop::DNSNative->new(reactor => $loop->reactor);

  $dns->lookup(
    'google.com',
    sub {
      my ($err, @ips) = @_;
      die "Could not look up google.com: $err" if $err;

      say for @ips;
    }
  );

  $loop->start;

=head1 DESCRIPTION

Look up hostnames using L<Net::DNS::Native> in a L<Mojo::IOLoop> without blocking.

=head1 ATTRIBUTES

L<Mojo::IOLoop::DNSNative> implements the following attributes.

=head2 NDN

  my $ndn = $dns->NDN;
  $dns    = $dns->NDN(Net::DNS::Native->new(pool => 5, extra_thread => 1));

The underlying L<Net::DNS::Native> object used to perform lookups.

=head2 reactor

  my $reactor = $dns->reactor;
  $dns        = $dns->reactor(Mojo::Reactor::Poll->new);

Low-level event reactor, defaults to the C<reactor> attribute of the global L<Mojo::IOLoop> singleton.

=head2 timeout

  my $timeout = $dns->timeout;
  $dns        = $dns->timeout(10);

Sets the timeout for lookups. Use 0 to disable timeouts.

=head1 METHODS

L<Mojo::IOLoop::DNSNative> implements the following methods.

=head2 lookup

  $dns->lookup(
    $host,
    sub {
      my ($err, @ips) = @_;
      die "Could not lookup $host: $err" if $err;

      say "$host resolves to @ips";
    }
  );

Look up a hostname using L<Net::DNS::Native> and get all the IPs it resolves to.

=head1 SEE ALSO

=over 4

=item L<Mojo::IOLoop>

=item L<Net::DNS::Native>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut

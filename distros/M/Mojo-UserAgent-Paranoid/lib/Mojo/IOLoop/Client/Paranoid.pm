package Mojo::IOLoop::Client::Paranoid 0.01;
use 5.020;
use experimental 'signatures';

use IO::Socket::IP;
use IO::Socket::UNIX;
use Scalar::Util qw(weaken);
use Socket       qw(IPPROTO_TCP SOCK_STREAM TCP_NODELAY);
use Mojo::Base 'Mojo::IOLoop::Client';

use Net::DNS::Paranoid; # does this handle IPv6 ??

=head1 NAME

Mojo::IOLoop::Client::Paranoid - paranoid IOLoop proxy

=head1 SYNOPSIS

    my $user_client = Mojo::IOLoop::Client::Paranoid->new(
      paranoid_dns => Net::DNS::Paranoid->new(
          blocked_hosts => [qr{\.dev.example\.com$}]
      ),
    );
    $user_client->connect($host); # will not connect to internal hosts

=head1 METHODS

=head2 C<< ->new >>

  my $client = Mojo::IOLoop::Client::Paranoid->new(
    paranoid_dns => Net::DNS::Paranoid->new(...),
  )

Creates a new paranoid client. The C<< ->connect >> method will check that the
given hostname does not resolve to any internal or blacklisted IP address.
See L<Net::DNS::Paranoid> for how to configure the white- and blacklists.

=cut

use constant NNR => $ENV{MOJO_NO_NNR} ? 0 : !!eval { require Net::DNS::Native; Net::DNS::Native->VERSION('0.15'); 1 };
our $NDN;

has 'paranoid_dns' => sub { Net::DNS::Paranoid->new() };

# We can't easily override the DNS resolver that Mojolicious uses as it is
# a lexical variable, and everything else would involve monkeypatching.
# So we copy the relevant code here.

sub _port { $_[0]{socks_port} || $_[0]{port} || ($_[0]{tls} ? 443 : 80) }

sub connect( $self, @args) {
  my ($args) = (ref $args[0] ? $args[0] : {@args});
  # Timeout
  weaken $self;
  my $reactor = $self->reactor;
  my $r = $reactor;
  $self->{timer} = $reactor->timer($args->{timeout} || 10, sub { $self->emit(error => 'Connect timeout') });
  # Blocking name resolution
  $_ && s/[[\]]//g for @$args{qw(address socks_address)};
  my $address = $args->{socks_address} || ($args->{address} ||= '127.0.0.1');
  return $reactor->next_tick(sub { $self && $self->_connect($args) }) if !NNR || $args->{handle} || $args->{path};
  # Non-blocking name resolution
  my $paranoid_dns = $self->paranoid_dns;

  if( $paranoid_dns->_bad_host($args->{address})) {
    # We need to delay the error by one tick so the callback variables get
    # initialized
    # warn "Immediate bad host ($self)";
    return $reactor->next_tick( sub { warn "Lost self" unless $self; $self && $self->emit(error => "Can't connect: Bad host '$args->{address}'"); undef $self });
  }

  $NDN //= Net::DNS::Native->new(pool => 5, extra_thread => 1);
  #warn "# Using Net::DNS::Native to resolve '$address'";
  my $handle = $self->{dns}
    = $NDN->getaddrinfo($address, _port($args), {protocol => IPPROTO_TCP, socktype => SOCK_STREAM});
  $reactor->io(
    $handle => sub {
      my $reactor = shift;
      $reactor->remove($self->{dns});
      my ($err, @res) = $NDN->get_result(delete $self->{dns});
      return $self->emit(error => "Can't resolve: $err") if $err;

      #use Data::Dumper;
      #warn "# $address resolved via Net::DNS::Native: " . Dumper \@res;

      $args->{addr_info} = \@res;
      $self->_connect($args);
    }
  )->watch($handle, 1, 0);
}

sub _to_address( $self, $addrinfo) {
    return $addrinfo->{family} == AF_INET ?
                inet_ntoa((unpack_sockaddr_in($addrinfo->{addr}))[1]) :                   # IPv4
                Socket::inet_ntop(AF_INET6, (unpack_sockaddr_in6($addrinfo->{addr}))[1]); # IPv6
}

sub _connect($self, $args) {
  my $path   = $args->{path};
  my $handle = $self->{handle} = $args->{handle};
  unless ($handle) {
    my $paranoid_dns = $self->paranoid_dns;
    my $class   = $path ? 'IO::Socket::UNIX' : 'IO::Socket::IP';
    my %options = (Blocking => 0);

    # UNIX domain socket
    if ($path) { $options{Peer} = $path }
    # IP socket
    else {
      if(!$args->{addr_info}) {
        my ($resolved, $errmsg) = $paranoid_dns->resolve($args->{address});
        if( $resolved ) {
            my $addr = $resolved->[0];
            $options{PeerAddr} = $resolved;
        } else {
            return $self->emit(error => "Bad host: $errmsg");
        }
      }

      if (my $info = $args->{addr_info}) {
        #use Data::Dumper; warn "Using pre-received addr_info " . Dumper $info;

        my $addr = $self->_to_address( $info->[0] );

        my ($resolved, $errmsg) = $paranoid_dns->_bad_host( $addr );
        if( $errmsg ) {
            return $self->emit(error => "Bad host: $errmsg");
        };
        $options{PeerAddrInfo} = $info;

      } else {
        $options{PeerAddr} = $args->{socks_address} || $args->{address};
        $options{PeerPort} = _port($args);
      }
      @options{keys %{$args->{socket_options}}} = values %{$args->{socket_options}} if $args->{socket_options};
    }
    return $self->emit(error => "Can't connect: $@") unless $self->{handle} = $handle = $class->new(%options);
  }
  $handle->blocking(0);
  $path ? $self->_try_socks($args) : $self->_wait('_ready', $handle, $args);
}

1;

=head1 SEE ALSO

L<Net::DNS::Paranoid>

L<Mojo::IOLoop::Client>

=cut


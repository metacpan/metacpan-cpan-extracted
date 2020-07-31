package Net::IPAM::IP;

our $VERSION = '1.24';

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp            ();
use Socket          ();
use Net::IPAM::Util ();

=head1 NAME

Net::IPAM::IP - A library for reading, formatting, sorting and converting IP-addresses.

=head1 SYNOPSIS

  use Net::IPAM::IP;

  # parse and normalize
  $ip1 = Net::IPAM::IP->new('1.2.3.4') // die 'wrong format,';
  $ip2 = Net::IPAM::IP->new('fe80::1') // die 'wrong format,';

  $ip3 = $ip2->incr // die 'overflow,';

  say $ip1;    # 1.2.3.4
  say $ip2;    # fe80::1
  say $ip3;    # fe80::2

  $ip3 = $ip2->decr // die 'underflow,';

  say $ip1;    # 1.2.3.4
  say $ip2;    # fe80::1
  say $ip3;    # fe80::0

  say $ip1->cmp($ip2);    # -1

  say $ip2->expand;       # fe80:0000:0000:0000:0000:0000:0000:0001
  say $ip2->reverse;      # 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f

  $ip = Net::IPAM::IP->new_from_bytes( pack( 'C4', 192,    168,   0, 1 ) );                 # 192.168.0.1
  $ip = Net::IPAM::IP->new_from_bytes( pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1, ) );    # 2001:db8::1

  @ips = Net::IPAM::IP->getaddrs('dns.google.');
  say "@ips";  #  8.8.8.8 8.8.4.4 2001:4860:4860::8844 2001:4860:4860::8888

=cut

=head1 CONSTRUCTORS

=head2 new

  $ip = Net::IPAM::IP->new("::1");

Parse the input string as IPv4/IPv6 address and returns the IP address object.

IPv4-mapped-IPv6 addresses are normalized and sorted as IPv4 addresses.

  ::ffff:1.2.3.4    => 1.2.3.4

Returns undef on illegal input.

=cut

sub new {
  my $self  = bless( {}, $_[0] );
  my $input = $_[1] // Carp::croak 'missing argument';

  # IPv4
  if ( index( $input, ':' ) < 0 ) {
    my $n = Socket::inet_pton( Socket::AF_INET, $input );
    return unless defined $n;

    $self->{version} = 4;
    $self->{binary}  = chr(Socket::AF_INET) . $n;
    return $self;
  }

  # IPv4-mapped-IPv6
  if ( index( $input, '.' ) >= 0 ) {
    my $ip4m6 = $input;

    # remove leading ::ffff: or return undef
    return unless $ip4m6 =~ s/^::ffff://i;

    my $n = Socket::inet_pton( Socket::AF_INET, $ip4m6 );
    return unless defined $n;

    $self->{version} = 4;
    $self->{binary}  = chr(Socket::AF_INET) . $n;
    return $self;
  }

  # IPv6 address
  my $n = Socket::inet_pton( Socket::AF_INET6, $input );
  return unless defined $n;

  $self->{version} = 6;
  $self->{binary}  = chr(Socket::AF_INET6) . $n;
  return $self;
}

=head2 new_from_bytes

  $ip = Net::IPAM::IP->new_from_bytes("\x0a\x00\x00\x01")

Parse the input as packed IPv4/IPv6/IPv4-mapped-IPv6 address and returns the IP address object.

Croaks on illegal input.

Can be used for cloning the object:

  $clone = $obj->new_from_bytes($obj->bytes);

=cut

sub new_from_bytes {
  my $self = bless( {}, ref $_[0] || $_[0] );
  my $n    = $_[1];
  Carp::croak('missing argument') unless defined $n;

  if ( length($n) == 4 ) {
    $self->{version} = 4;
    $self->{binary}  = chr(Socket::AF_INET) . $n;
    return $self;
  }
  elsif ( length($n) == 16 ) {

    # check for IPv4-mapped IPv6 address ::ffff:1.2.3.4
    if ( index( $n, "\x00" x 10 . "\xff\xff" ) == 0 ) {
      my $ipv4 = substr( $n, 12 );
      $self->{version} = 4;
      $self->{binary}  = chr(Socket::AF_INET) . $ipv4;
      return $self;
    }

    $self->{version} = 6;
    $self->{binary}  = chr(Socket::AF_INET6) . $n;
    return $self;
  }

  Carp::croak 'illegal input';
}

=head2 getaddrs($name, [$error_cb])

Returns a list of ip objects for a given $name or undef if there is no RR record for $name.

  my @ips = Net::IPAM::IP->getaddrs('dns.google.');
  say "@ips";  #  8.8.8.8 8.8.4.4 2001:4860:4860::8844 2001:4860:4860::8888

L</"getaddrs"> calls the L<Socket> function C<< getaddrinfo() >> under the hood.

With no error callback L</getaddrs> just calls C<< carp() >> with underlying Socket errors.

For granular error handling use your own error callback:

  my $my_error_cb = sub {
    my $error = shift;
    # check the $error and do what you want
    ...
  }

  my @ips = Net::IPAM::IP->getaddrs( $name, $my_error_cb );

or shut up the default error handler with:

  my @ips = Net::IPAM::IP->getaddrs( $name, sub { } );

ANNOTATION: This constructor could also be named C<< new_from_name >> but it behaves differently
because it returns a B<list> of objects and supports an optional argument as error callback,
reporting underlying Socket errors.

=cut

# heuristic detection of ip addrs as input
my $v4_rx       = qr/^[0-9.]+$/;
my $v6_rx       = qr/^[a-fA-F0-9:]+$/;
my $v4mapv6_rx  = qr/^::[a-fA-F]+:[0-9.]+$/;
my $v4compv6_rx = qr/^::[0-9.]+$/;

my $ip_rx = qr/$v4_rx|$v6_rx|$v4mapv6_rx|$v4compv6_rx/;

sub getaddrs {
  my ( $class, $name, $error_cb ) = @_;
  Carp::croak('missing argument') unless defined $name;

  $error_cb = \&Carp::carp unless defined $error_cb;

  # just ip address as input param, don't rely on (buggy) Socket getaddrinfo
  return $class->new($name) if $name =~ $ip_rx;

  # resolve name
  my ( $err, @res ) =
    Socket::getaddrinfo( $name, "", { socktype => Socket::SOCK_RAW, family => Socket::AF_UNSPEC } );

  if ($err) {

    # no error, just no resolveable name
    return if $err == Socket::EAI_NONAME;

    $error_cb->("getaddrinfo($name): $err");
    return;
  }

  # unpack sockaddr struct
  my @ips;
  while ( my $ai = shift @res ) {
    my $n;
    if ( $ai->{family} == Socket::AF_INET ) {
      $n = substr( $ai->{addr}, 4, 4 );
    }
    else {
      $n = substr( $ai->{addr}, 8, 16 );
    }
    push @ips, $class->new_from_bytes($n);
  }

  return @ips;
}

=head1 METHODS

L<Net::IPAM::IP> implements the following methods:

=head2 cmp

Compare IP objects, returns -1, 0, +1

  $this->cmp($other)

  @sorted_ips = sort { $a->cmp($b) } @unsorted_ips;

Fast bytewise lexical comparison of the binary representation in network byte order.

IPv4 addresses are B<always> treated as smaller than IPv6 addresses (::ffff:0.0.0.0 < ::)

=cut

# the first byte is the version: IPv4 is sorted before IPv6
# there is no utf8-flag in packed values,
# we can just use string compare for the bytes
sub cmp {
  $_[0]->{binary} cmp $_[1]->{binary};
}

=head2 version

  $v = Net::IPAM::IP->new('fe80::1')->version    # 6

Returns 4 or 6.

=cut

sub version {
  $_[0]->{version};
}

=head2 to_string

Returns the input string in canonical form.

  lower case hexadecimal characters
  zero compression
  remove leading zeros

  say Net::IPAM::IP->new('Fe80::0001')->to_string;  # fe80::1

Stringification is overloaded with L</"to_string">

  my $ip = Net::IPAM::IP->new('Fe80::0001') // die 'wrong format';
  say $ip; # fe80::1

=cut

# without inet_ntop bug it would be easy, sic
#sub to_string {
#  return $_[0]->{as_string} if exists $_[0]->{as_string};
#  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
#  return $_[0]->{as_string} = Socket::inet_ntop( $v, $n );
#}

# circumvent IPv4-compatible-IPv6 bug in Socket::inet_ntop
sub to_string {
  return $_[0]->{as_string} if exists $_[0]->{as_string};

  # unpack to version and network byte order (from Socket::inet_pton), 20% faster with substr()
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  my $str = Socket::inet_ntop( $v, $n );

  # no bug in Socket::inet_ntop for IPv4, just return
  return $_[0]->{as_string} = $str if $v == Socket::AF_INET;

  # handle bug in Socket::inet_ntop for deprecated IPv4-compatible-IPv6 addresses
  # ::aaaa:bbbb are returned as ::hex(aa).hex(aa).hex(bb).hex(bb) = ::170.170.187.187
  # e.g: ::cafe:affe => ::202.254.175.254

  # first handle normal case, no dot '.'
  if ( index( $str, '.' ) < 0 ) {
    return $_[0]->{as_string} = $str;
  }

  # handle the bug, use our pure perl inet_ntop
  return $_[0]->{as_string} = Net::IPAM::Util::inet_ntop_pp( $v, $n );
}

=head2 incr

Returns the next IP address, returns undef on overflow.

  $next_ip = Net::IPAM::IP->new('fe80::1')->incr // die 'overflow,';
  say $next_ip;   # fe80::2

=cut

sub incr {
  my $n_plus1 = Net::IPAM::Util::incr_n( $_[0]->bytes );

  # overflow?
  return unless defined $n_plus1;

  # sort of cloning
  $_[0]->new_from_bytes($n_plus1);
}

=head2 decr

Returns the previous IP address, returns undef on underflow.

  $prev_ip = Net::IPAM::IP->new('fe80::1')->decr // die 'overflow,';
  say $prev_ip;   # fe80::

=cut

sub decr {
  my $n_minus1 = Net::IPAM::Util::decr_n( $_[0]->bytes );

  # underflow?
  return unless defined $n_minus1;

  # sort of cloning
  $_[0]->new_from_bytes($n_minus1);
}

=head2 expand

Expand IP address into canonical form, useful for C<< grep >>, aligned output and lexical C<< sort >>

	Net::IPAM::IP->new('1.2.3.4')->expand;   # '001.002.003.004'
	Net::IPAM::IP->new('fe80::1')->expand;   # 'fe80:0000:0000:0000:0000:0000:0000:0001'

=cut

sub expand {
  return $_[0]->{expand} if exists $_[0]->{expand};

  # unpack to version and network byte order (from Socket::inet_pton), substr() ist faster than unpack
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  if ( $v == Socket::AF_INET6 ) {
    my @hextets = unpack( 'H4' x 8, $n );

    # cache it and return
    return $_[0]->{expand} = join( ':', @hextets );
  }
  elsif ( $v == Socket::AF_INET ) {
    my @octets = unpack( 'C4', $n );

    # cache it and return
    return $_[0]->{expand} = sprintf( "%03d.%03d.%03d.%03d", @octets );
  }
  die 'logic error,';
}

=head2 reverse

Reverse IP address, needed for PTR entries in DNS zone files.

 Net::IPAM::IP->new('fe80::1')->reverse; # '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f'
 Net::IPAM::IP->new('1.2.3.4')->reverse; # '4.3.2.1'

=cut

sub reverse {
  return $_[0]->{reverse} if exists $_[0]->{reverse};

  # unpack to version and network byte order (from Socket::inet_pton)
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
  # substr() ist faster
  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  if ( $v == Socket::AF_INET6 ) {
    my $hex_str = unpack( 'H*',     $n );
    my @nibbles = unpack( 'A' x 32, $hex_str );

    # cache it and return
    return $_[0]->{reverse} = join( '.', reverse @nibbles );
  }
  elsif ( $v == Socket::AF_INET ) {
    my @octets = unpack( 'C4', $n );

    # cache it and return
    return $_[0]->{reverse} = join( '.', reverse @octets );
  }
  die 'logic error,';
}

=head2 getname([$error_cb])

Returns the DNS name for the ip object or undef if there is no PTR RR.

  say Net::IPAM::IP->new('2001:4860:4860::8888')->getname;   # dns.google.

L</"getname"> calls the L<Socket> function C<< getnameinfo() >> under the hood.

With no error callback L</getname> just calls C<< carp() >> with underlying Socket errors.

=head3 LIMITATION:

Returns just one name even if the IP has more than one PTR RR. This is a limitation
of Socket::getnameinfo. If you need all names for IPs with more than one PTR RR then you should
use L<Net::DNS> or similar modules.

=cut

sub getname {
  my ( $self, $error_cb ) = @_;
  $error_cb = \&Carp::carp unless defined $error_cb;

  my $sock_addr;
  if ( $self->{version} == 4 ) {
    $sock_addr = Socket::pack_sockaddr_in( 0, $self->bytes );
  }
  else {
    $sock_addr = Socket::pack_sockaddr_in6( 0, $self->bytes );
  }

  my ( $err, $name ) = Socket::getnameinfo( $sock_addr, Socket::NI_NAMEREQD, Socket::NIx_NOSERV );

  if ($err) {

    # no error, just no resolveable name
    return if $err == Socket::EAI_NONAME;

    $error_cb->("getnameinfo($self): $err");
    return;
  }

  $name;
}

=head2 bytes

  $ip = Net::IPAM::IP->new('fe80::');
  $bytes = $ip->bytes;    # "\xfe\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

  $ip    = Net::IPAM::IP->new('10.0.0.1');
  $bytes = $ip->bytes;    # "\x0a\x00\x00\x01"

Returns the packed IP address as byte-string. It's the opposite to L</"new_from_bytes">

=cut

# drop first byte (version) and return the packed IP address,
sub bytes {
  substr( $_[0]->{binary}, 1 );
}

=head1 OPERATORS

L<Net::IPAM::IP> overloads the following operators.

=head2 bool

  my $bool = !!$ip;

Always true.

=head2 stringify

  my $str = "$ip";

Alias for L</"to_string">.

=cut

use overload
  '""'     => sub { shift->to_string },
  bool     => sub { 1 },
  fallback => 1;

=head1 WARNING

Some Socket::inet_XtoY implementations are hopelessly buggy.

Tests are made during loading and in case of errors, these functions are redefined
with a (slower) pure-perl implementation.

=cut

# On some platforms, inet_pton accepts various forms of invalid input or discards valid input.
# In this case use a (slower) pure-perl implementation for Socket::inet_pton.
# and also for Socket::inet_ntop, I don't trust that too.
BEGIN {
  if (    # wrong valid
       defined Socket::inet_pton( Socket::AF_INET,  '010.0.0.1' )
    || defined Socket::inet_pton( Socket::AF_INET,  '10.000.0.1' )
    || defined Socket::inet_pton( Socket::AF_INET6, 'cafe:::' )
    || defined Socket::inet_pton( Socket::AF_INET6, 'cafe::1::' )
    || defined Socket::inet_pton( Socket::AF_INET6, 'cafe::1:' )
    || defined Socket::inet_pton( Socket::AF_INET6, ':cafe::' )

    # wrong invalid
    || !defined Socket::inet_pton( Socket::AF_INET6, 'caFe::' )
    || !defined Socket::inet_pton( Socket::AF_INET6, '::' )
    || !defined Socket::inet_pton( Socket::AF_INET,  '0.0.0.0' )
    )
  {
    no warnings 'redefine';
    *Socket::inet_pton = \&Net::IPAM::Util::inet_pton_pp;
    *Socket::inet_ntop = \&Net::IPAM::Util::inet_ntop_pp;
  }
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ipam-ip at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IPAM-IP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::IP


You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 SEE ALSO

L<Net::IPAM::Util>
L<Net::IPAM::Block>
L<Net::IPAM::Tree>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of Net::IPAM::IP

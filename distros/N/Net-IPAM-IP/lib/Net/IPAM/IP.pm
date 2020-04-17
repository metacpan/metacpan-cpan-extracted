package Net::IPAM::IP;

use strict;
use warnings;
our $VERSION = '1.14';

use Socket qw/:addrinfo AF_INET AF_INET6 AF_UNSPEC SOCK_RAW/;

# On some platforms, inet_pton accepts various forms of invalid input or discards valid input.
# In this case use a (slower) pure-perl implementation for Socket::inet_pton.
# and also for Socket::inet_ntop, I don't trust that too.
BEGIN {
  if (    # wrong valid
       defined Socket::inet_pton( AF_INET,  '010.0.0.1' )
    || defined Socket::inet_pton( AF_INET,  '10.000.0.1' )
    || defined Socket::inet_pton( AF_INET6, 'cafe:::' )
    || defined Socket::inet_pton( AF_INET6, 'cafe::1::' )
    || defined Socket::inet_pton( AF_INET6, 'cafe::1:' )
    || defined Socket::inet_pton( AF_INET6, ':cafe::' )

    # wrong invalid
    || !defined Socket::inet_pton( AF_INET6, 'caFe::' )
    )
  {
    no warnings 'redefine';
    *Socket::inet_pton = \&_inet_pton_pp;
    *Socket::inet_ntop = \&_inet_ntop_pp;
  }
}

use Carp qw/croak/;
use Exporter 'import';
our @EXPORT_OK = qw(incr_n);

use overload
  '""'     => sub { shift->to_string },
  bool     => sub { 1 },
  fallback => 1;

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

  say $ip1->cmp($ip2);    # -1

  say $ip2->expand;       # fe80:0000:0000:0000:0000:0000:0000:0001
  say $ip2->reverse;      # 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f

  $ip = Net::IPAM::IP->new_from_bytes(pack('C4', 192, 168, 0, 1));       # 192.168.0.1
  $ip = Net::IPAM::IP->new_from_bytes(pack('N4', 0x20010db8, 0, 0, 1,)); # 2001:db8::1

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
  croak 'wrong method call' unless defined $_[1];
  my $self = bless( {}, ref $_[0] || $_[0] );

  # IPv4
  if ( index( $_[1], ':' ) < 0 ) {
    my $n = Socket::inet_pton( AF_INET, $_[1] ) // return;
    $self->{version} = 4;
    $self->{binary}  = chr(AF_INET) . $n;
    return $self;
  }

  # IPv4-mapped-IPv6
  if ( index( $_[1], '.' ) >= 0 ) {
    my $ip4m6 = $_[1];

    # remove leading ::ffff: or return undef
    return unless $ip4m6 =~ s/^::ffff://i;

    my $n = Socket::inet_pton( AF_INET, $ip4m6 ) // return;

    $self->{version} = 4;
    $self->{binary}  = chr(AF_INET) . $n;
    return $self;
  }

  # IPv6 address
  my $n = Socket::inet_pton( AF_INET6, $_[1] ) // return;
  $self->{version} = 6;
  $self->{binary}  = chr(AF_INET6) . $n;
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
  croak 'wrong method call' unless defined $_[1];
  my $self = bless( {}, ref $_[0] || $_[0] );
  my $n    = $_[1];

  if ( length($n) == 4 ) {
    $self->{version} = 4;
    $self->{binary}  = chr(AF_INET) . $n;
    return $self;
  }
  elsif ( length($n) == 16 ) {

    # check for IPv4-mapped IPv6 address ::ffff:1.2.3.4
    if ( index( $n, "\x00" x 10 . "\xff\xff" ) == 0 ) {
      my $ipv4 = substr( $n, 12 );
      $self->{version} = 4;
      $self->{binary}  = chr(AF_INET) . $ipv4;
      return $self;
    }

    $self->{version} = 6;
    $self->{binary}  = chr(AF_INET6) . $n;
    return $self;
  }

  croak 'illegal input,';
}

=head2 getaddrs($name, [$error_cb])

Returns a list of ip objects for a given $name or undef if there is no RR record for $name.

  my @ips = Net::IPAM::IP->getaddrs('dns.google.');
  say "@ips";  #  8.8.8.8 8.8.4.4 2001:4860:4860::8844 2001:4860:4860::8888

L</"getaddrs"> calls the L<Socket> functions C<< getaddrinfo() >> and C<< getnameinfo() >> under the hood.

With no error callback L</getaddrs> just calls C<< warn() >> with underlying Socket errors.

For granular error handling use your own error callback:

  my $my_error_cb = sub {
    my ( $error, $msg) = @_;
    # check the $error and do what you want with error and message
    ...
  }

  my @ips = Net::IPAM::IP->getaddrs( $name, $my_error_cb );

or shut up the default error handler with:

  my @ips = Net::IPAM::IP->getaddrs( $name, sub { } );

ANNOTATION: This constructor could also be named C<< new_from_name >> but it behaves differently
because it returns a B<list> of objects and supports an optional argument as error callback,
reporting underlying Socket errors.

=cut

sub getaddrs {
  my ( $class, $name, $error_cb ) = @_;
  $error_cb //= sub { warn "@_" };

  unless ( defined $name ) {
    $error_cb->( 0, "missing argument" );
    return;
  }

  my ( $err, @res ) = getaddrinfo( $name, "", { socktype => SOCK_RAW, family => AF_UNSPEC } );

  if ($err) {

    # no error, just no resolveable name
    return if $err == EAI_NONAME;

    $error_cb->( $err, "getaddrinfo($name)" );
    return;
  }

  my @ips;

  while ( my $ai = shift @res ) {
    my ( $err, $ip ) = getnameinfo( $ai->{addr}, NI_NUMERICHOST, NIx_NOSERV );

    if ($err) {
      $error_cb->( $err, "getnameinfo($name)" );
      return;
    }

    push @ips, $class->new($ip);
  }

  return @ips;
}

=head1 METHODS

L<Net::IPAM::IP> implements the following methods:

=head2 bytes

  $ip = Net::IPAM::IP->new('fe80::');
  $bytes = $ip->bytes;    # "\xfe\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

  $ip    = Net::IPAM::IP->new('10.0.0.1');
  $bytes = $ip->bytes;    # "\x0a\x00\x00\x01"

Returns the packed IP address as byte-string. It's the opposite to L</"new_from_bytes">

=cut

sub bytes {

  # drop first byte (version) and return the packed IP address,
  return substr( $_[0]->{binary}, 1 );
}

=head2 cmp

Compare IP objects, returns -1, 0, +1

  $this->cmp($other)

  @sorted_ips = sort { $a->cmp($b) } @unsorted_ips;

Fast bytewise lexical comparison of the binary representation in network byte order.

IPv4 addresses are always treated as smaller than IPv6 addresses.

=cut

sub cmp {
  croak "wrong or missing arg" unless ref $_[1] && $_[1]->isa(__PACKAGE__);

  # the first byte is the version: IPv4 is sorted before IPv6
  # there is no utf8-flag in packed values,
  # we can use just string compare for the bytes

  return $_[0]->{binary} cmp $_[1]->{binary};
}

=head2 version

  $v = Net::IPAM::IP->new('fe80::1')->version    # 6

Returns 4 or 6.

=cut

sub version {
  return $_[0]->{version} if defined $_[0]->{version};

  # unpack first byte, AF_INETx, 20% faster with substr()
  # my $v = unpack( 'C', $_[0]->{binary} );

  my $v = ord( substr( $_[0]->{binary}, 0, 1 ) );

  # get, cache and return
  return $_[0]->{version} = 4 if $v == AF_INET;
  return $_[0]->{version} = 6 if $v == AF_INET6;
  die 'logic error,';
}

=head2 to_string

Returns the input string in canonical form.

  lower case hexadecimal characters
  zero compression
  remove leading zeros

  say Net::IPAM::IP->new('Fe80::0001')->to_string;  # fe80::1

Stringification is overloaded with L</"to_string">

  my $ip = Net::IPAM::IP->new('Fe80::0001') // die 'wrong format,';;
  say $ip; # fe80::1

=cut

# without inet_ntop bug it would be easy, sic
#sub to_string {
#  return $_[0]->{string} if defined $_[0]->{string};
#  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
#  return $_[0]->{string} = Socket::inet_ntop( $v, $n );
#}

# circumvent IPv4-compatible-IPv6 bug in Socket::inet_ntop
sub to_string {

  # unpack to version and network byte order (from Socket::inet_pton), 20% faster with substr()
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  my $str = Socket::inet_ntop( $v, $n );

  # no bug in Socket::inet_ntop for IPv4, just return
  return $str if $v == AF_INET;

  # handle bug in Socket::inet_ntop for deprecated IPv4-compatible-IPv6 addresses
  # ::aaaa:bbbb are returned as ::hex(aa).hex(aa).hex(bb).hex(bb) = ::170.170.187.187
  # e.g: ::cafe:affe => ::202.254.175.254

  # first handle normal case, no dot '.'
  if ( index( $str, '.' ) < 0 ) {
    return $str;
  }

  # handle the bug, use our pure perl inet_ntop
  return _inet_ntop_pp( $v, $n );
}

=head2 incr

Returns the next IP address, returns undef on overflow.

  $next_ip = Net::IPAM::IP->new('fe80::1')->incr // die 'overflow,';
  say $next_ip;   # fe80::2

=cut

sub incr {
  my $n = incr_n( $_[0]->bytes ) // return;
  return ( ref $_[0] )->new_from_bytes($n);
}

=head2 expand

Expand IP address into canonical form, useful for C<< grep >>, aligned output and lexical C<< sort >>

	Net::IPAM::IP->new('1.2.3.4')->expand;   # '001.002.003.004'
	Net::IPAM::IP->new('fe80::1')->expand;   # 'fe80:0000:0000:0000:0000:0000:0000:0001'

=cut

sub expand {
  return $_[0]->{expand} if defined $_[0]->{expand};

  # unpack to version and network byte order (from Socket::inet_pton), substr() ist faster than unpack
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  if ( $v == AF_INET6 ) {
    my @hextets = unpack( 'H4' x 8, $n );

    # cache it and return
    return $_[0]->{expand} = join( ':', @hextets );
  }
  elsif ( $v == AF_INET ) {
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
  return $_[0]->{reverse} if defined $_[0]->{reverse};

  # unpack to version and network byte order (from Socket::inet_pton)
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
  # substr() ist faster
  my ( $v, $n ) = ( ord( substr( $_[0]->{binary}, 0, 1 ) ), substr( $_[0]->{binary}, 1, ) );

  if ( $v == AF_INET6 ) {
    my $hex_str = unpack( 'H*',     $n );
    my @nibbles = unpack( 'A' x 32, $hex_str );

    # cache it and return
    return $_[0]->{reverse} = join( '.', reverse @nibbles );
  }
  elsif ( $v == AF_INET ) {
    my @octets = unpack( 'C4', $n );

    # cache it and return
    return $_[0]->{reverse} = join( '.', reverse @octets );
  }
  die 'logic error,';
}

=head2 getname([$error_cb])

Returns the DNS name for the ip object or undef if there is no PTR RR.

  say Net::IPAM::IP->new('2001:4860:4860::8888')->getname;   # dns.google.

L</"getname"> calls the L<Socket> functions C<< getaddrinfo() >> and C<< getnameinfo() >> under the hood.

With no error callback L</getname> just calls C<< warn() >> with underlying Socket errors.

=head3 LIMITATION:

Returns just one name even if the IP has more than one PTR RR. This is a limitation
of Socket::getnameinfo. If you need all names for IPs with more than one PTR RR then you should
use L<Net::DNS> or similar modules.

=cut

sub getname {
  my $error_cb = $_[1] // sub { warn "@_" };

  my ( $err, @res ) =
    getaddrinfo( $_[0], '', { socktype => SOCK_RAW, flags => AI_NUMERICHOST, family => AF_UNSPEC } );

  if ($err) {
    $error_cb->( $err, "getaddrinfo($_[0])" );
    return;
  }

  my $name;
  ( $err, $name ) = getnameinfo( $res[0]->{addr}, NI_NAMEREQD, NIx_NOSERV );
  if ($err) {

    # no error, just no resolveable name
    return if $err == EAI_NONAME;

    $error_cb->( $err, "getnameinfo($_[0])" );
    return;
  }

  return $name;
}

=head1 FUNCTIONS

L<Net::IPAM::IP> implements the following functions;

=head2 incr_n($n)

Increment a packed IPv4 or IPv6 address, no need for L<Math::BigInt>. Needed by methods in L<Net::IPAM::Block>.

=cut

sub incr_n {
  my $n = shift;

  # length in bytes / 4 => length in long (32 bits)
  my $pos = length($n) / 4 - 1;

  # start at least significant long
  my $long = vec( $n, $pos, 32 );

  # carry?
  while ( $long == 0xffff_ffff ) {

    # OVERFLOW, this long is already the most significant long!
    return if $pos == 0;

    # set this long to zero
    vec( $n, $pos, 32 ) = 0;

    # carry on to next more significant long
    $long = vec( $n, --$pos, 32 );
  }

  # incr this long
  vec( $n, $pos, 32 ) = ++$long;
  return $n;
}

# make fast 'tail' calls, goto &NAME
# modify @_ = (AF_INETx, $ip) => @_ = ($ip)
sub _inet_ntop_pp {
  my $v = shift;
  goto &_inet_ntop_v4_pp if $v == AF_INET;
  goto &_inet_ntop_v6_pp if $v == AF_INET6;
  return;
}

sub _inet_ntop_v4_pp {
  my $n = shift // return;
  return if length($n) != 4;
  return join( '.', unpack( 'C4', $n ) );
}

# (1) Hexadecimal digits are expressed as lower-case letters.
#     For example, 2001:db8::1 is preferred over 2001:DB8::1.
#
# (2) Leading zeros in each 16-bit field are suppressed.
#     For example, 2001:0db8::0001 is rendered as 2001:db8::1,
#     though any all-zero field that is explicitly presented is rendered as 0.
#
# (3) Representations are shortened as much as possible.
#     The longest sequence of consecutive all-zero fields is replaced with double-colon.
#     If there are multiple longest runs of all-zero fields, then it is the leftmost that is compressed.
#     E.g., 2001:db8:0:0:1:0:0:1 is rendered as 2001:db8::1:0:0:1 rather than as 2001:db8:0:0:1::1.
#
# (4) "::" is not used to shorten just a single 0 field.
#     For example, 2001:db8:0:0:0:0:2:1 is shortened to 2001:db8::2:1,
#     but 2001:db8:0000:1:1:1:1:1 is rendered as 2001:db8:0:1:1:1:1:1.
#
sub _inet_ntop_v6_pp {
  my $n = shift // return;
  return if length($n) != 16;

  # expand binary to hex, lower case, rule (1), leading zeroes squashed
  # add : at left and right for symmetric squashing algo, see below
  # :2001:db8:85a3:0:0:8a2e:370:7334:
  my $ip = sprintf( ':%x:%x:%x:%x:%x:%x:%x:%x:', unpack( 'n8', $n ) );

  # rule (3,4) # squash the longest sequence of consecutive all-zero fields
  # e.g. :0:0: (?!not followed) :0\1
  $ip =~ s/(:0[:0]+:) (?! .+ :0\1)/::/x;

  $ip =~ s/^:// unless $ip =~ /^::/;    # trim additional left
  $ip =~ s/:$// unless $ip =~ /::$/;    # trim additional right
  return $ip;
}

# make fast 'tail' calls, goto &NAME
# modify @_ = (AF_INETx, $ip) => @_ = ($ip)
sub _inet_pton_pp {
  my $v = shift;
  goto &_inet_pton_v4_pp if $v == AF_INET;
  goto &_inet_pton_v6_pp if $v == AF_INET6;
  return;
}

# @_ = ($ip)
sub _inet_pton_v4_pp {

  # 'C' may overflow for values > 255, check below
  no warnings qw(pack numeric);
  my $n = pack( 'C4', split( /\./, $_[0] ) );

  # unpack(pack...) must be idempotent
  # check for overflow errors or leading zeroes
  return unless $_[0] eq join( '.', unpack( 'C4', $n ) );

  return $n;
}

# @_ = ($ip)
sub _inet_pton_v6_pp {
  my $ip = shift // return;

  return if $ip =~ m/[^a-fA-F0-9:]/;
  return if $ip =~ m/:::/;

  # starts with just one colon: :cafe...
  return if $ip =~ m/^:[^:]/;

  # ends with just one colon: ..:cafe:affe:
  return if $ip =~ m/[^:]:$/;

  my $col_count     = $ip =~ tr/://;
  my $dbl_col_count = $ip =~ s/::/::/g;

  return if $col_count > 7;
  return if $dbl_col_count > 1;
  return if $dbl_col_count == 0 && $col_count != 7;

  # normalize for splitting, prepend or append 0
  $ip =~ s/^:: /0::/x;
  $ip =~ s/ ::$/::0/x;

  # expand ::
  my $expand_dbl_col = ':0' x ( 8 - $col_count ) . ':';
  $ip =~ s/::/$expand_dbl_col/;

  my @hextets = split( /:/, $ip );
  return if grep { length > 4 } @hextets;

  my $n = pack( 'n8', map { hex } @hextets );
  return $n;
}

=head1 OPERATORS

L<Net::IPAM::IP> overloads the following operators.

=head2 bool

  my $bool = !!$ip;

Always true.

=head2 stringify

  my $str = "$ip";

Alias for L</"to_string">.

=head1 WARNING

Some Socket::inet_XtoY implementations are hopelessly buggy.

Tests are made during loading and in case of errors, these functions are redefined
with a (slower) pure-perl implementation.

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

L<Net::IPAM::Block>
L<Net::IPAM::Tree>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of Net::IPAM::IP

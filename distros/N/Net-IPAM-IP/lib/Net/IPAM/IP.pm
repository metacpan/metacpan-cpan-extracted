package Net::IPAM::IP;

use strict;
use warnings;
our $VERSION = '1.08';

use Socket qw/AF_INET AF_INET6/;

# On some platforms, inet_pton accepts various forms of invalid input or discards valid input.
# In this case use a (slower) pure perl implementation for Socket::inet_pton.
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

=cut

=head1 METHODS

Net::IPAM::IP implements the following methods:

=head2 new

Parse the input string as IPv4/IPv6 address and returns the IP address object.

IPv4-mapped-IPv6 addresses are normalized and sorted as IPv4 addresses.

  ::ffff:1.2.3.4    => 1.2.3.4

Returns undef on illegal input.

=cut

sub new {
  croak 'wrong method call' unless defined $_[1];
  my $self = bless( {}, $_[0] );

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

=head2 clone

Just a shallow copy

=cut

sub clone {
  return bless( { binary => $_[0]->{binary} }, ref $_[0] );
}

=head2 new_from_bytes

  $ip = Net::IPAM::IP->new_from_bytes("\x0a\x00\x00\x01")

Parse the input as packed IPv4/IPv6/IPv4-mapped-IPv6 address and returns the IP address object.

Croaks on illegal input.

=cut

sub new_from_bytes {
  croak 'wrong method call' unless defined $_[1];
  my $self = bless( {}, $_[0] );
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

=head2 bytes

  $ip = Net::IPAM::IP->new('fe80::');
  $bytes = $ip->bytes;    # "\xfe\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

  $ip    = Net::IPAM::IP->new('10.0.0.1');
  $bytes = $ip->bytes;    # "\x0a\x00\x00\x01"

Returns the packed IP address as byte-string. It's the opposite to new_from_bytes()

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

  # unpack first byte, AF_INETx
  # my $v = unpack( 'C', $_[0]->{binary} );
  #
  # 20% faster with substr()
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

Stringification is overloaded with C<to_string>

  my $ip = Net::IPAM::IP->new('Fe80::0001') // die 'wrong format,';;
  say $ip; # fe80::1

=cut

# without inet_ntop bug it would be easy, sic
#sub to_string {
#  return $_[0]->{string} if defined $_[0]->{string};
#  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
#  return $_[0]->{string} = Socket::inet_ntop( $v, $n );
#}

# circumvent IPv4-compatible-IPv4 bug in Socket::inet_ntop
sub to_string {

  # unpack to version and network byte order (from Socket::inet_pton)
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
  #
  # 20% faster with substr()
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
  return Net::IPAM::IP->new_from_bytes($n);
}

=head2 expand

Expand IP address into canonical form, useful for grep, aligned output and lexical sort.

	Net::IPAM::IP->new('1.2.3.4')->expand;   # '001.002.003.004'
	Net::IPAM::IP->new('fe80::1')->expand;   # 'fe80:0000:0000:0000:0000:0000:0000:0001'

=cut

sub expand {
  return $_[0]->{expand} if defined $_[0]->{expand};

  # unpack to version and network byte order (from Socket::inet_pton)
  # my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );
  # substr() ist faster
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

=head1 FUNCTIONS

Net::IPAM::IP implements the following functions;

=head2 incr_n($n)

Increment packed IPv4 or IPv6 address, no need for Math::BigInt. Needed by methods in Net::IPAM::Block.

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

  # expand binary to hex, lower case, rule (1)
  # 2001:0db8:85a3:0000:0000:8a2e:0370:7334
  my $ip = join( ':', unpack( 'H4' x 8, $n ) );

  # squash leading zeroes, rule (2)
  # 2001:db8:85a3:0:0:8a2e:370:7334
  $ip =~ s/\b 0{1,3}//gx;

  # find all consecutive groups containing zeros
  my $rx     = qr/(?:^|:) [0:]+ /x;
  my @groups = $ip =~ m/$rx/g;

  # find longest group (count zeros with tr///), rule (3)
  # count zeros with tr///
  my $max_str   = '';
  my $max_zeros = 0;

  foreach my $match (@groups) {
    my $zeroes = $match =~ tr/0/0/;
    if ( $zeroes > $max_zeros ) {
      $max_zeros = $zeroes;
      $max_str   = $match;
    }
  }

  # the substitution may only be applied once in the address, rule (3,4)
  # "::" is not used to shorten just a single 0 field
  if ( $max_zeros >= 2 ) {
    $ip =~ s/$max_str/::/;
  }

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

=head1 WARNINGS

Some Socket::inet_pton implementations are hopelessly buggy and are redefined during loading.

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

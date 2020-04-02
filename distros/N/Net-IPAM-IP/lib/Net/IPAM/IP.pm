package Net::IPAM::IP;

use strict;
use warnings;

use overload
  '""'     => sub { shift->to_string },
  fallback => 1;

use Carp qw/croak/;
use Socket qw/AF_INET AF_INET6 inet_pton inet_ntop/;

use Exporter 'import';
our @EXPORT_OK = qw(incr_n);

our $VERSION = '1.00';

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
    my $n = inet_pton( AF_INET, $_[1] ) // return;
    $self->{version} = 4;
    $self->{binary}  = pack( 'C a*', AF_INET, $n );
    return $self;
  }

  # IPv4-mapped-IPv6
  if ( index( $_[1], '.' ) >= 0 ) {

    # remove leading ::ffff: with substr()
    my $n = inet_pton( AF_INET, substr( $_[1], 7 ) ) // return;

    $self->{version} = 4;
    $self->{binary}  = pack( 'C a*', AF_INET, $n );
    return $self;
  }

  # IPv6 address
  my $n = inet_pton( AF_INET6, $_[1] ) // return;
  $self->{version} = 6;
  $self->{binary}  = pack( 'C a*', AF_INET6, $n );
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
    $self->{binary}  = pack( 'C a*', AF_INET, $n );
    return $self;
  }
  elsif ( length($n) == 16 ) {

    # check for IPv4-mapped IPv6 address ::ffff:1.2.3.4
    if ( index( $n, "\x00" x 10 . "\xff\xff" ) == 0 ) {
      my $ipv4 = unpack( 'x12 a4', $n );
      $self->{version} = 4;
      $self->{binary}  = pack( 'C a*', AF_INET, $ipv4 );
      return $self;
    }

    $self->{version} = 6;
    $self->{binary}  = pack( 'C a*', AF_INET6, $n );
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
  return unpack( 'x a*', $_[0]->{binary} );
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
  my $v = unpack( 'C', $_[0]->{binary} );

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
#  return $_[0]->{string} = inet_ntop( $v, $n );
#}

# circumvent IPv4-compatible-IPv4 bug in inet_ntop
sub to_string {

  # unpack to version and network byte order (from inet_pton)
  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

  my $str = inet_ntop( $v, $n );

  # no bug in inet_ntop for IPv4, just return
  return $str if $v == AF_INET;

  # handle bug in inet_ntop for deprecated IPv4-compatible-IPv6 addresses
  # ::aaaa:bbbb are returned as ::hex(aa).hex(aa).hex(bb).hex(bb) = ::170.170.187.187
  # e.g: ::cafe:affe => ::202.254.175.254

  # first handle normal case, no dot '.'
  if ( index( $str, '.' ) < 0 ) {
    return $str;
  }

  # here we handle the bug, strip off leading '::'
  $str = substr( $str, 2 );

  # split to 4 octets
  my @octets = split( /\./, $str );

  # convert to hextets, insert leading '::'
  $str = sprintf( '::%02x%02x:%02x%02x', @octets );

  # strip leading zeros in hextets ::0aff:000e -> ::aff:e
  # OMG, write once read never, look-ahead-behind tricks and /g flag
  $str =~ s/
						 (?<![0-9a-f])  # negative lookbehind, (no leading hex_digit)
						 0+          # at least one 0 or more (substitute with nothing)
						 (?=[0-9a-f])   # positive lookahead, (followed by a hex_digit)
						//gx;

  return $str;
}

=head2 incr

Returns the next IP address, returns undef on overflow.

  $next_ip = Net::IPAM::IP->new('fe80::1')->incr // die 'overflow,';
  say $next_ip;   # fe80::2

=cut

sub incr {
	my $n = incr_n($_[0]->bytes) // return;
	return Net::IPAM::IP->new_from_bytes($n);
}

=head2 expand

Expand IP address into canonical form, useful for grep, aligned output and lexical sort.

	Net::IPAM::IP->new('1.2.3.4')->expand;   # '001.002.003.004'
	Net::IPAM::IP->new('fe80::1')->expand;   # 'fe80:0000:0000:0000:0000:0000:0000:0001'

=cut

sub expand {
  return $_[0]->{expand} if defined $_[0]->{expand};

  # unpack to version and network byte order (from inet_pton)
  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

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

  # unpack to version and network byte order (from inet_pton)
  my ( $v, $n ) = unpack( 'C a*', $_[0]->{binary} );

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


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of Net::IPAM::IP

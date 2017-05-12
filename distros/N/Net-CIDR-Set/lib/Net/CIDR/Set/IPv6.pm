package Net::CIDR::Set::IPv6;

use warnings;
use strict;
use Carp;

=head1 NAME

Nset::CIDR::Set::IPv6 - Encode / decode IPv6 addresses

=head1 VERSION

This document describes Net::CIDR::Set::IPv6 version 0.13

=cut

our $VERSION = '0.13';

sub new { bless \my $x, shift }

sub _pack_ipv4 {
  my @nums = split /[.]/, shift, -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and $_ < 256;
  }
  return pack "CC*", 0, @nums;
}

sub _426 {
  my @nums = split /[.]/, shift, -1;
  return if grep $_ > 255, @nums;
  return join( ":", unpack( 'H*', pack 'C*', @nums ) =~ /..../g );
}

sub _pack {
  my $ip = shift;
  return pack( 'H*', '0' x 33 ) if $ip eq '::';
  return if $ip =~ /^:/ and $ip !~ s/^::/:/;
  return if $ip =~ /:$/ and $ip !~ s/::$/:/;
  my @nums = split /:/, $ip, -1;
  return unless @nums <= 8;
  my ( $empty, $ipv4, $str ) = ( 0, '', '' );
  for ( @nums ) {
    return if $ipv4;
    $str .= "0" x ( 4 - length ) . $_, next if /^[a-fA-F\d]{1,4}$/;
    do { return if $empty++ }, $str .= "X", next if $_ eq '';
    next if $ipv4 = _pack_ipv4( $_ );
    return;
  }
  return if $ipv4 and @nums > 6;
  $str =~ s/X/"0" x (($ipv4 ? 25 : 33)-length($str))/e if $empty;
  return pack( "H*", "00" . $str ) . $ipv4;
}

sub _unpack {
  return _compress_ipv6(
    join( ":", unpack( "xH*", shift ) =~ /..../g ) );
}

# Replace longest run of null blocks with a double colon
sub _compress_ipv6 {
  my $ip = shift;
  if ( my @runs = $ip =~ /((?:(?:^|:)(?:0000))+:?)/g ) {
    my $max = $runs[0];
    for ( @runs[ 1 .. $#runs ] ) {
      $max = $_ if length( $max ) < length;
    }
    $ip =~ s/$max/::/;
  }
  $ip =~ s/:0{1,3}/:/g;
  return $ip;
}

sub _width2bits {
  my ( $width, $size ) = @_;
  return pack 'B*',
   ( '1' x ( $width + 8 ) ) . ( '0' x ( $size - $width ) );
}

sub _is_cidr {
  my ( $lo, $hi ) = @_;
  my $mask = ~( $lo ^ $hi );
  my $bits = unpack 'B*', $mask;
  return unless $hi eq ($lo | $hi);
  return unless $bits =~ /^(1*)0*$/;
  return length( $1 ) - 8;
}

sub _encode {
  my ( $self, $ip ) = @_;
  if ( $ip =~ m{^(.+?)/(.+)$} ) {
    my $mask = $2;
    return unless my $addr = _pack( $1 );
    return unless my $bits = _width2bits( $mask, 128 );
    return ( $addr & $bits, Net::CIDR::Set::_inc( $addr | ~$bits ) );
  }
  elsif ( $ip =~ m{^(.+?)-(.+)$} ) {
    my ( $from, $to ) = ( $1, $2 );
    return unless my $lo = _pack( $from );
    return unless my $hi = _pack( $to );
    return ( $lo, Net::CIDR::Set::_inc( $hi ) );
  }
  else {
    return $self->_encode( "$ip/128" );
  }
}

sub encode {
  my ( $self, $ip ) = @_;
  my @r = $self->_encode( $ip )
   or croak "Can't decode $ip as an IPv6 address";
  return @r;
}

sub decode {
  my $self    = shift;
  my $lo      = shift;
  my $hi      = Net::CIDR::Set::_dec( shift );
  my $generic = shift || 0;
  if ( $generic < 1 && $lo eq $hi ) {
    # Single address
    return _unpack( $lo );
  }
  elsif ( $generic < 2 && defined( my $w = _is_cidr( $lo, $hi ) ) ) {
    # Valid CIDR range
    return join '/', _unpack( $lo ), $w;
  }
  else {
    # General range
    return join '-', _unpack( $lo ), _unpack( $hi );
  }
}

sub nbits { 128 }

1;
__END__

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2009, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

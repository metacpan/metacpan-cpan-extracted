package Net::CIDR::Set::IPv4;

use warnings;
use strict;
use Carp;

=head1 NAME

Net::CIDR::Set::IPv4 - Encode / decode IPv4 addresses

=head1 VERSION

This document describes Net::CIDR::Set::IPv4 version 0.13

=cut

our $VERSION = '0.13';

sub new { bless \my $x, shift }

sub _pack {
  my @nums = split /[.]/, shift, -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and $_ < 256;
  }
  return pack "CC*", 0, @nums;
}

sub _unpack { join ".", unpack "xC*", shift }

sub _width2bits {
  my ( $width, $size ) = @_;
  return pack 'B*',
   ( '1' x ( $width + 8 ) ) . ( '0' x ( $size - $width ) );
}

sub _ip2bits {
  my $ip = shift or return;
  vec( $ip, 0, 8 ) = 255;
  my $bits = unpack 'B*', $ip;
  return unless $bits =~ /^1*0*$/;    # Valid mask?
  return $ip;
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
    return
     unless my $bits
       = ( $mask =~ /^\d+$/ )
      ? _width2bits( $mask, 32 )
      : _ip2bits( _pack( $mask ) );
    return ( $addr & $bits, Net::CIDR::Set::_inc( $addr | ~$bits ) );
  }
  elsif ( $ip =~ m{^(.+?)-(.+)$} ) {
    return unless my $lo = _pack( $1 );
    return unless my $hi = _pack( $2 );
    return ( $lo, Net::CIDR::Set::_inc( $hi ) );
  }
  else {
    return $self->_encode( "$ip/32" );
  }
}

sub encode {
  my ( $self, $ip ) = @_;
  my @r = $self->_encode( $ip )
   or croak "Can't decode $ip as an IPv4 address";
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

sub nbits { 32 }

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

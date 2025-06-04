package Net::CIDR::Set::IPv4;

use warnings;
use strict;
use Carp;

use namespace::autoclean;

# ABSTRACT: Encode / decode IPv4 addresses

our $VERSION = '0.16';

sub new { bless \my $x, shift }

sub _pack {
  my @nums = split /[.]/, shift, -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and !/^0\d{1,2}$/ and $_ < 256;
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

=pod

=encoding UTF-8

=head1 NAME

Net::CIDR::Set::IPv4 - Encode / decode IPv4 addresses

=head1 VERSION

version 0.16

=for Pod::Coverage new

=for Pod::Coverage encode

=for Pod::Coverage decode

=for Pod::Coverage nbits

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Net-CIDR-Set>
and may be cloned from L<git://github.com/robrwo/perl-Net-CIDR-Set.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-CIDR-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Andy Armstrong <andy@hexten.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009, 2014, 2025 by Message Systems, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

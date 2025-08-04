package Net::CIDR::Set::IPv6;

use warnings;
use strict;
use Carp;

use namespace::autoclean;

# ABSTRACT: Encode / decode IPv6 addresses

our $VERSION = '0.18';

sub new { bless \my $x, shift }

sub _pack_ipv4 {
  my @nums = split /[.]/, shift, -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and !/^0\d{1,2}$/ and $_ < 256;
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

=pod

=encoding UTF-8

=head1 NAME

Net::CIDR::Set::IPv6 - Encode / decode IPv6 addresses

=head1 VERSION

version 0.18

=for Pod::Coverage new

=for Pod::Coverage encode

=for Pod::Coverage decode

=for Pod::Coverage nbits

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Net-CIDR-Set>
and may be cloned from L<git://github.com/robrwo/perl-Net-CIDR-Set.git>

=head1 SUPPORT

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

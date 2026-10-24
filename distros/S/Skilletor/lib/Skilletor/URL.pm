package Skilletor::URL;
# ABSTRACT: The parts of a URL as the WHATWG URL parser (Node's new URL) gives them

use strict;
use warnings;

use Encode ();
use Exporter qw( import );
use Skilletor::FSUtil qw( decode_utf8_lossy );
use Unicode::Normalize ();

our $VERSION = '0.001';

our @EXPORT_OK = qw( parse_url punycode_encode );

my %SPECIAL = map { $_ => 1 } qw( ftp file http https ws wss );
my %DEFAULT_PORT = ( ftp => 21, http => 80, https => 443, ws => 80, wss => 443 );

# Forbidden host code points; a domain also forbids C0 controls, "%" and DEL.
my $FORBIDDEN_HOST   = qr/[\x00\t\n\r #\/:<>?\@\[\\\]^|]/;
my $FORBIDDEN_DOMAIN = qr/[\x00-\x1F #%\/:<>?\@\[\\\]^|\x7F]/;

sub _pct_encode {
  my ( $s, $set ) = @_;
  $s =~ s{($set)}{ join '', map { sprintf '%%%02X', $_ } unpack 'C*', Encode::encode( 'UTF-8', $1 ) }ge;
  return $s;
}

# The path percent-encode set: C0 controls, space, " # < > ? ` { } and everything above "~".
my $PATH_SET = qr/[\x00-\x20"#<>?`{}\x7F-\x{10FFFF}]/;
my $C0_SET   = qr/[\x00-\x1F\x7F-\x{10FFFF}]/;

sub _pct_decode_bytes {
  my ( $s ) = @_;
  my $bytes = Encode::encode( 'UTF-8', $s );
  $bytes =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  return $bytes;
}

sub parse_url {
  my ( $input ) = @_;
  my $s = $input;
  $s =~ s/\A[\x00-\x20]+//;
  $s =~ s/[\x00-\x20]+\z//;
  $s =~ s/[\t\n\r]//g;
  return undef unless $s =~ /\A([A-Za-z][A-Za-z0-9+.\-]*):(.*)\z/s;
  my ( $scheme, $rest ) = ( lc $1, $2 );
  my $special = $SPECIAL{$scheme} ? 1 : 0;
  my %url = ( protocol => $scheme.':', username => '', password => '', hostname => '', port => '', search => '', hash => '' );

  # fragment and query
  if ( $rest =~ s/#(.*)\z//s ) { $url{hash} = length $1 ? '#'.$1 : '' }
  if ( $rest =~ s/\?(.*)\z//s ) { $url{search} = length $1 ? '?'.$1 : '' }

  my $sep = $special ? qr{[/\\]} : qr{/};
  my $path;
  if ( $special && $scheme ne 'file' ) {
    $rest =~ s{\A[/\\]+}{};
    my ( $authority, $p ) = $rest =~ m{\A([^/\\]*)(.*)\z}s;
    return undef unless _authority( \%url, $authority, $scheme, 1 );
    return undef if $url{hostname} eq '';
    $path = $p;
  }
  elsif ( $scheme eq 'file' ) {
    if ( $rest =~ s{\A[/\\]{2}}{} ) {
      my ( $host, $p ) = $rest =~ m{\A([^/\\]*)(.*)\z}s;
      if ( length $host ) {
        my $h = _host( $host, 1 );
        return undef unless defined $h;
        $url{hostname} = $h eq 'localhost' ? '' : $h;
      }
      $path = $p;
    }
    else {
      $path = $rest;
    }
  }
  elsif ( $rest =~ s{\A//}{} ) {
    my ( $authority, $p ) = $rest =~ m{\A([^/]*)(.*)\z}s;
    return undef unless _authority( \%url, $authority, $scheme, 0 );
    $path = $p;
  }
  else {
    # an opaque path: kept, C0 controls encoded
    $url{pathname} = _pct_encode( $rest, $C0_SET );
    return \%url;
  }

  my @segments;
  if ( $special || length $path ) {
    $path =~ s{\A$sep}{};
    my @raw = split /$sep/, $path, -1;
    @raw = ('') unless @raw;
    for my $i ( 0 .. $#raw ) {
      my $seg  = $raw[$i];
      my $last = $i == $#raw;
      if ( $seg =~ /\A(?:\.|%2e)(?:\.|%2e)\z/i ) {
        pop @segments;
        push @segments, '' if $last;
      }
      elsif ( $seg =~ /\A(?:\.|%2e)\z/i ) {
        push @segments, '' if $last;
      }
      else {
        push @segments, _pct_encode( $seg, $PATH_SET );
      }
    }
  }
  $url{pathname} = join '', map { '/'.$_ } @segments;
  return \%url;
}

sub _authority {
  my ( $url, $authority, $scheme, $special ) = @_;
  my $hostport = $authority;
  my $at = rindex $authority, '@';
  if ( $at >= 0 ) {
    my $userinfo = substr $authority, 0, $at;
    $hostport = substr $authority, $at + 1;
    my ( $user, $pass ) = split /:/, $userinfo, 2;
    $url->{username} = $user // '';
    $url->{password} = $pass // '';
  }
  my ( $host, $port ) = ( $hostport, '' );
  if ( $hostport =~ /\A(\[[^\]]*\])(?::(.*))?\z/s ) {
    ( $host, $port ) = ( $1, $2 // '' );
  }
  elsif ( ( my $c = index $hostport, ':' ) >= 0 ) {
    ( $host, $port ) = ( substr( $hostport, 0, $c ), substr( $hostport, $c + 1 ) );
  }
  if ( length $port ) {
    return 0 unless $port =~ /\A[0-9]+\z/;
    return 0 if $port > 65535;
    $port = 0 + $port;
    $port = '' if defined $DEFAULT_PORT{$scheme} && $port == $DEFAULT_PORT{$scheme};
  }
  $url->{port} = "$port";
  return 0 if $special && $host eq '';
  return 1 if $host eq '';
  my $h = _host( $host, $special );
  return 0 unless defined $h;
  $url->{hostname} = $h;
  return 1;
}

sub _host {
  my ( $input, $special ) = @_;
  if ( $input =~ /\A\[/ ) {
    return undef unless $input =~ /\A\[([0-9A-Fa-f:.]+)\]\z/;
    return '['.lc($1).']';
  }
  unless ($special) {
    return undef if $input =~ $FORBIDDEN_HOST;
    return _pct_encode( $input, $C0_SET );
  }
  my $domain = decode_utf8_lossy( _pct_decode_bytes($input) );
  my $ascii  = _domain_to_ascii($domain);
  return undef unless defined $ascii && length $ascii;
  return undef if $ascii =~ $FORBIDDEN_DOMAIN;
  if ( _ends_in_number($ascii) ) {
    return _ipv4($ascii);
  }
  return $ascii;
}

# UTS #46 lite: NFC and lower case, then each label holding non-ASCII as punycode.
sub _domain_to_ascii {
  my ( $domain ) = @_;
  my $mapped = lc Unicode::Normalize::NFC($domain);
  $mapped =~ s/[\x{3002}\x{FF0E}\x{FF61}]/./g;
  my @labels = split /\./, $mapped, -1;
  for my $label (@labels) {
    next unless $label =~ /[^\x00-\x7F]/;
    my $encoded = punycode_encode($label);
    return undef unless defined $encoded;
    $label = 'xn--'.$encoded;
  }
  return join '.', @labels;
}

sub _ipv4_number {
  my ( $s ) = @_;
  return undef if $s eq '';
  my $radix = 10;
  if ( $s =~ s/\A0[xX]// ) { $radix = 16 }
  elsif ( length $s > 1 && $s =~ s/\A0// ) { $radix = 8 }
  return 0 if $s eq '';
  return $radix == 16 ? ( $s =~ /\A[0-9A-Fa-f]+\z/ ? hex $s : undef )
       : $radix == 8  ? ( $s =~ /\A[0-7]+\z/ ? oct $s : undef )
       :                ( $s =~ /\A[0-9]+\z/ ? 0 + $s : undef );
}

sub _ends_in_number {
  my ( $host ) = @_;
  my @parts = split /\./, $host, -1;
  if ( @parts && $parts[-1] eq '' ) {
    return 0 if @parts == 1;
    pop @parts;
  }
  my $last = $parts[-1] // '';
  return 1 if $last ne '' && $last =~ /\A[0-9]+\z/;
  return defined _ipv4_number($last) ? 1 : 0;
}

sub _ipv4 {
  my ( $host ) = @_;
  my @parts = split /\./, $host, -1;
  pop @parts if @parts > 1 && $parts[-1] eq '';
  return undef if @parts > 4;
  my @n;
  for my $p (@parts) {
    my $v = _ipv4_number($p);
    return undef unless defined $v;
    push @n, $v;
  }
  for my $i ( 0 .. $#n - 1 ) { return undef if $n[$i] > 255 }
  return undef if $n[-1] >= 256**( 5 - @n );
  my $ipv4 = $n[-1];
  $ipv4 += $n[$_] * 256**( 3 - $_ ) for 0 .. $#n - 1;
  return join '.', map { ( $ipv4 >> ( 8 * ( 3 - $_ ) ) ) & 255 } 0 .. 3;
}

# RFC 3492 punycode of one label (without the xn-- prefix).
sub punycode_encode {
  my ( $input ) = @_;
  my ( $base, $tmin, $tmax, $skew, $damp ) = ( 36, 1, 26, 38, 700 );
  my ( $n, $delta, $bias ) = ( 128, 0, 72 );
  my @cp = map { ord } split //, $input;
  my $output = join '', map { chr } grep { $_ < 128 } @cp;
  my $basic = length $output;
  my $h = $basic;
  $output .= '-' if $basic > 0;
  my $digit = sub { my $d = shift; chr( $d < 26 ? 97 + $d : 22 + $d ) };
  my $adapt = sub {
    my ( $d, $num, $first ) = @_;
    $d = $first ? int( $d / $damp ) : int( $d / 2 );
    $d += int( $d / $num );
    my $k = 0;
    while ( $d > ( ( $base - $tmin ) * $tmax ) / 2 ) {
      $d = int( $d / ( $base - $tmin ) );
      $k += $base;
    }
    return $k + int( ( ( $base - $tmin + 1 ) * $d ) / ( $d + $skew ) );
  };
  while ( $h < @cp ) {
    my ($m) = sort { $a <=> $b } grep { $_ >= $n } @cp;
    $delta += ( $m - $n ) * ( $h + 1 );
    $n = $m;
    for my $c (@cp) {
      $delta++ if $c < $n;
      next unless $c == $n;
      my $q = $delta;
      for ( my $k = $base ; ; $k += $base ) {
        my $t = $k <= $bias ? $tmin : $k >= $bias + $tmax ? $tmax : $k - $bias;
        last if $q < $t;
        $output .= $digit->( $t + ( $q - $t ) % ( $base - $t ) );
        $q = int( ( $q - $t ) / ( $base - $t ) );
      }
      $output .= $digit->($q);
      $bias = $adapt->( $delta, $h + 1, $h == $basic );
      $delta = 0;
      $h++;
    }
    $delta++;
    $n++;
  }
  return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::URL - The parts of a URL as the WHATWG URL parser (Node's new URL) gives them

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::URL qw( parse_url );

  my $u = parse_url('https://user@Example.COM:443/a/../b c?x#y');
  # { protocol => 'https:', hostname => 'example.com', port => '',
  #   pathname => '/b%20c', search => '?x', hash => '#y', ... }
  my $bad = parse_url('https://example.com:99999/');   # undef: new URL throws

=head1 DESCRIPTION

The reference reads a URL with C<new URL()> where its answer reaches a name or
a decision: the derived name of an C<add> spec (C<hostname>, C<pathname>) and
the scheme check of a url source. This is the WHATWG parser for absolute URLs,
as far as those answers go: special and non-special schemes, userinfo, port
(digits, at most 65535, the default dropped), host (percent-decoding, lower
case, IDNA as NFC + lower case + punycode, IPv4 in every WHATWG form, IPv6
kept), path (dot segments, C<\> as a separator of special schemes, the path
percent-encode set). It does not validate IPv6 or apply the full UTS #46
mapping table.

=head2 parse_url

  my $parts = parse_url($input);

C<undef> where C<new URL($input)> throws; else
C<< { protocol, username, password, hostname, port, pathname, search, hash } >>.

=head2 punycode_encode

RFC 3492 punycode of one label.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

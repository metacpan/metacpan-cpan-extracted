package Skilletor::Gzip;
# ABSTRACT: gunzip and inflate as Node's zlib binding does them, with zlib's messages

use strict;
use warnings;

use Compress::Raw::Zlib ();
use Exporter qw( import );
use Skilletor::Error::Source;

our $VERSION = '0.001';

our @EXPORT_OK = qw( gunzip_sync inflate_sync );

sub _fail { Skilletor::Error::Source->throw( $_[0] ) }

# One zlib stream over all of $input. $gunzip: after a member's end, a 0x00 byte ends the
# input (padding); any other byte starts the next member – as node_zlib.cc does.
sub _run {
  my ( $input, $window_bits, $gunzip ) = @_;
  my ( $z, $status ) = Compress::Raw::Zlib::Inflate->new(
    -WindowBits   => $window_bits,
    -ConsumeInput => 1,
    -LimitOutput  => 0,
    -Bufsize      => 65536,
  );
  _fail( 'zlib: '.$status ) unless $z;
  my $out = '';
  my $in  = $input;
  while (1) {
    my $chunk = '';
    my $st = $z->inflate( $in, $chunk );
    $out .= $chunk;
    if ( $st == Compress::Raw::Zlib::Z_STREAM_END() ) {
      last unless $gunzip && length $in;
      last if substr( $in, 0, 1 ) eq "\0";
      $z->inflateReset;
      next;
    }
    if ( $st == Compress::Raw::Zlib::Z_OK() ) {
      next if length $in;
      _fail('unexpected end of file');
    }
    if ( $st == Compress::Raw::Zlib::Z_BUF_ERROR() ) {
      _fail('unexpected end of file');
    }
    _fail( $z->msg // "$st" );
  }
  return $out;
}

sub gunzip_sync {
  my ( $bytes ) = @_;
  return _run( $bytes, Compress::Raw::Zlib::WANT_GZIP(), 1 );
}

# Content-Encoding: deflate – zlib-wrapped when the first byte says so, else raw (undici).
sub inflate_sync {
  my ( $bytes ) = @_;
  my $zlib = length $bytes && ( ord( substr $bytes, 0, 1 ) & 0x0F ) == 0x08;
  return _run( $bytes, $zlib ? Compress::Raw::Zlib::MAX_WBITS() : -Compress::Raw::Zlib::MAX_WBITS(), 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Gzip - gunzip and inflate as Node's zlib binding does them, with zlib's messages

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Gzip qw( gunzip_sync );

  my $tar = gunzip_sync($tar_gz);   # throws "incorrect header check", "unexpected end of file", ...

=head1 DESCRIPTION

A url source's archive is gunzipped as the reference's C<gunzipSync> does it:
zlib's gzip mode, several members one after another, trailing input after a
member ignored when it starts with a zero byte. A failure throws a
L<Skilletor::Error::Source> with zlib's message, so a fallback warning reads
the same in both implementations.

=head2 gunzip_sync

  my $bytes = gunzip_sync($gz);

C<zlib.gunzipSync>.

=head2 inflate_sync

For a C<Content-Encoding: deflate> response.

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

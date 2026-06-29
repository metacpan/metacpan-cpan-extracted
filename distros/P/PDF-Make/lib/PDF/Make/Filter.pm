package PDF::Make::Filter;

use strict;
use warnings;
use PDF::Make ();

our $VERSION = '0.04';

# Thin wrappers around the PDF::Make XS codec functions defined in xs/filter.xs.
# These let Perl tests exercise the ASCII85, ASCIIHex, Flate, Raw DEFLATE, LZW,
# RunLength and PNG/TIFF predictor implementations directly instead of only
# through the end-to-end writer/reader pipelines.

sub ascii85_encode  { PDF::Make::Filter::_ascii85_encode($_[0]) }
sub ascii85_decode  { PDF::Make::Filter::_ascii85_decode($_[0]) }
sub asciihex_encode { PDF::Make::Filter::_asciihex_encode($_[0]) }
sub asciihex_decode { PDF::Make::Filter::_asciihex_decode($_[0]) }

sub rle_encode      { PDF::Make::Filter::_rle_encode($_[0]) }
sub rle_decode      { PDF::Make::Filter::_rle_decode($_[0]) }

sub flate_encode    { PDF::Make::Filter::_flate_encode($_[0]) }
sub flate_decode    { PDF::Make::Filter::_flate_decode($_[0]) }

sub deflate_encode  { PDF::Make::Filter::_deflate_encode($_[0], $_[1] // 6) }
sub deflate_decode  { PDF::Make::Filter::_deflate_decode($_[0]) }

sub adler32         { PDF::Make::Filter::_adler32($_[0]) }

sub lzw_decode      {
    my ($data, %opts) = @_;
    PDF::Make::Filter::_lzw_decode($data, $opts{early_change} // 1);
}

sub predictor_encode {
    my %opt = @_;
    PDF::Make::Filter::_predictor_encode(
        $opt{predictor} // 10,
        $opt{colors}    // 1,
        $opt{bits}      // 8,
        $opt{columns}   // 1,
        $opt{data},
    );
}

sub predictor_decode {
    my %opt = @_;
    PDF::Make::Filter::_predictor_decode(
        $opt{predictor} // 10,
        $opt{colors}    // 1,
        $opt{bits}      // 8,
        $opt{columns}   // 1,
        $opt{data},
    );
}

sub tiff_predictor_encode {
    my %opt = @_;
    PDF::Make::Filter::_tiff_predictor_encode(
        $opt{colors} // 1, $opt{bits} // 8, $opt{columns} // 1, $opt{data},
    );
}

sub tiff_predictor_decode {
    my %opt = @_;
    PDF::Make::Filter::_tiff_predictor_decode(
        $opt{colors} // 1, $opt{bits} // 8, $opt{columns} // 1, $opt{data},
    );
}

1;

__END__

=head1 NAME

PDF::Make::Filter - Perl access to PDF stream filters (Flate, ASCII85, LZW, etc.)

=head1 SYNOPSIS

    use PDF::Make::Filter;

    my $encoded = PDF::Make::Filter::flate_encode("hello world");
    my $plain   = PDF::Make::Filter::flate_decode($encoded);

    my $a85 = PDF::Make::Filter::ascii85_encode("Man is distinguished");
    my $raw = PDF::Make::Filter::ascii85_decode($a85);

    my $rle = PDF::Make::Filter::rle_encode("AAAABBBCC");
    my $pred = PDF::Make::Filter::predictor_encode(
        predictor => 12, columns => 4, data => $row_data,
    );

=head1 DESCRIPTION

Thin wrappers around the XS-exposed PDF stream filter implementations from
C<libpdfmake>.  Intended primarily for unit testing.

=head1 FUNCTIONS

=over 4

=item C<ascii85_encode>, C<ascii85_decode>

ASCII-85 codec (§7.4.3).  Output of C<encode> is terminated with C<~E<gt>>.

=item C<asciihex_encode>, C<asciihex_decode>

ASCIIHex codec (§7.4.2).  Encoded form uses uppercase and terminates with
C<E<gt>>.

=item C<flate_encode>, C<flate_decode>

zlib-wrapped DEFLATE codec (§7.4.4).

=item C<deflate_encode($bytes, $level)>, C<deflate_decode>

Raw DEFLATE codec (RFC 1951).  C<$level> is 0-9, default 6.

=item C<adler32($bytes)>

Adler-32 checksum (RFC 1950).

=item C<lzw_decode($bytes, early_change =E<gt> 1)>

LZW decoder (§7.4.4).

=item C<predictor_encode / predictor_decode>

PNG predictors (10-15) with C<predictor>, C<colors>, C<bits>, C<columns>,
and C<data> keyword args.

=item C<tiff_predictor_encode / tiff_predictor_decode>

TIFF predictor 2 (horizontal differencing).

=back

=head1 SEE ALSO

L<PDF::Make>

=cut

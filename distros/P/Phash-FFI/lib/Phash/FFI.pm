package Phash::FFI;
use strict;
use warnings;
our $VERSION = "0.04";

use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib(lib => "pHash"));

$ffi->attach( [ ph_dct_imagehash => '_ph_dct_imagehash' ] => [ 'string', 'uint64*' ] => 'int' );
$ffi->attach([ ph_hamming_distance => 'ph_hamming_distance' ] => [ 'int', 'int' ] => 'int');

sub dct_imagehash {
    my ($file_path) = @_;
    my $hash;
    my $rv = _ph_dct_imagehash($file_path, \$hash);
    return $hash;
}

1;

=head1 NAME

Phash::FFI - FFI-based pHash interface.

=head1 DESCRIPTION

Phash::FFI is the library adaptor for L<pHash|http://phash.org/>, which allows you to generate a hash value from media
files (image, video, audio). It is designed so that if 2 media files have identical hash value if they are perceptually
the same.

=head1 FUNCTIONS

=over 4

=item dct_imagehash($file_path)

This subroutine takes a path name and returns a 64-bit phash. For example:

    my $hash = Phash::FFI::dct_imagehash("Lenna.png");
    printf "%064b\t%s\n", $hash, $file;

    # output
    1100100100011100101100100110001001110111010110101001010110110001	Lenna.png

=item ph_hamming_distance($hash1, $hash2)

The similary of hash can be calculated by L<Hamming distance|http://en.wikipedia.org/wiki/Hamming_distance> of bits.

When 2 hash values have only 1 or 2 bits that are different, it is very likely that the corresponding 2 images look the same.

=back

=head1 SEE ALSO

L<Image::Hash>

=head1 LICENSE

Phash::FFI is released under MIT License.

L<pHash|http://phash.org/> is released under GPLv3 license.


use strict;
use warnings;
use Phash::FFI;

for my $file (@ARGV) {
    my $hash = Phash::FFI::dct_imagehash($file);
    printf "%064b\t%s\n", $hash, $file;
}


package Net::SSH::Perl::Util::SSH1Misc;
use strict;
use warnings;

use String::CRC32;

sub _crc32 {
    crc32($_[0], 0xFFFFFFFF) ^ 0xFFFFFFFF;
}

1;

# $Id: SSH1Misc.pm,v 1.1 2001/04/09 19:38:34 btrott Exp $

package Net::SSH::Perl::Util::SSH1Misc;
use strict;
use warnings;

use String::CRC32;

sub _crc32 {
    crc32($_[0], 0xFFFFFFFF) ^ 0xFFFFFFFF;
}

1;

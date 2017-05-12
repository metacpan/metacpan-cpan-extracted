package RFID::Libnfc::Tag::ISO14443A_106::Classic::MINI;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A_106::Classic);
use RFID::Libnfc;
use RFID::Libnfc::Constants;

our $VERSION = '0.13';

# number of blocks in the tag
sub blocks {
    return 5*4;
}

# number of sectors in the tag
sub sectors {
    return 5;
}

1;

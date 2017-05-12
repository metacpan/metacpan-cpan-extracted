package RFID::Libnfc::Tag::ISO14443A_106::Classic::4K;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A_106::Classic);

our $VERSION = '0.13';

# refer to : MF1S703x.pdf 
# for Classic-4K specification 

# The 4K 8 bit EEPROM memory is organized in 32 sectors of 4 block
# and 8 sectors of 16 blocks. One block contains 16 bytes 

# ACL and memory access (read/write) follows the same rules 
# defined in the generic mifare-classic spec (M001053_MF1ICS50_rev5_3.pdf)

# number of blocks in the tag
sub blocks {
    return 256;
}

# number of sectors in the tag
sub sectors {
    return 40;
}

1;

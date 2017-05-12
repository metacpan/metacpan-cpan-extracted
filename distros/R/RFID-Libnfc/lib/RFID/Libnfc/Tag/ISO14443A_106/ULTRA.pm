package RFID::Libnfc::Tag::ISO14443A_106::ULTRA;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A_106);
use RFID::Libnfc qw(nfc_configure nfc_initiator_transceive_bytes nfc_initiator_transceive_bits iso14443a_crc_append print_hex);
use RFID::Libnfc::Constants;

our $VERSION = '0.13';

my $ALLOW_LOCKINGBITS_CHANGES = 0;

sub read_block {
    my ($self, $block, $noauth, $truncate) = @_;

    my $cmd = pack("C4", MU_READ, $block);
    iso14443a_crc_append($cmd, 2);
    if (my $resp = nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 4)) {
        if ($self->{debug}) {
            printf("R: ");
            # don't dump out parity bytes, which will be dropped later
            # when returning the buffer back to the caller
            print_hex($resp, length($resp) -2); 
        }
        # if we are reading page 15 we must return only 4 bytes, 
        # since following 12 bytes will come from page 0 
        # (according to the the "roll back" property described in chapter 6.6.4 on 
        # the spec document : M028634_MF0ICU1_Functional_Spec_V3.4.pdf
        if ($block == $self->blocks-1 or $truncate) { 
            # if $truncate is true, we will return back the exact block
            # (which on ultralight tokens is 4 bytes, even if read returns always 16 bytes).
            return unpack("a4", $resp); 
        } else {
            return unpack("a16", $resp); 
        }
    } else {
        $self->{_last_error} = "Error reading block $block";
    }
    return undef;
}

sub write_block {
    my ($self, $block, $data) = @_;

    return undef unless $data;
    if ($block > 3 or $ALLOW_LOCKINGBITS_CHANGES) { # data block
        my $acl = $self->acl;
        return undef unless $acl;
        if ($acl->{plbits}->{$block}) {
            $self->{_last_error} = "Lockbits deny writes on block $block";
            return undef;
        }

        #my $len = (length($data) <= 4) ? 4 : 16;
        #my $cmdtag = ($len == 4)?MU_WRITE:MU_CWRITE;
        my $len = 4;
        my $cmdtag = MU_WRITE; # XXX use only standard WRITE command for now
        my $prefix = pack("C2", $cmdtag, $block);
        my $postfix = pack("C2", 0, 0);
        my $cmd = $prefix.pack("a".$len, $data).$postfix;
        iso14443a_crc_append($cmd, $len+2);
        if (nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, $len+4)) {
            if ($self->{debug}) {
                printf("W: ");
                print_hex($data);
            }
            if ($block == 2) {
                unless (nfc_initiator_transceive_bits($self->reader->pdi, pack("C", MU_WUPA), 7)) {
                    $self->{_last_error} = "Error committing blocking-bits changes";
                    return 0;
                }
            }
            return 1;
        } else {
            $self->{_last_error} = "Error trying to write on block $block";
        }
    } else {
        $self->{_last_error} = "You are actually not allowed to write on blocks 0, 1 and 2";
    }
    return undef;
}

sub allow_lockingbits_changes {
    my ($self, $bool) = @_;
    $ALLOW_LOCKINGBITS_CHANGES = $bool;
}

sub read_sector {
    my $self = shift;
    return $self->read_block(@_);
}

sub write_sector {
    my $self = shift;
    $self->write_block(@_);
}

# number of blocks on the tag
sub blocks {
    return 16;
}

# number of sectors on the tag
sub sectors {
    return 16;
}

sub acl {
    my $self = shift;

    #nfc_configure($self->reader->pdi, NDO_EASY_FRAMING, 1);
    my $data = $self->read_block(2);
    if ($data) {
        return $self->_parse_locking_bits(unpack("x2a2", $data));
    }
    $self->{_last_error} = "Can't read ACL from sector 2";
    return undef;
}

# locking-bits parsing as defined on M028634_MF0ICU1_Functional_Spec_V3.4.pdf 
sub _parse_locking_bits {
    my ($self, $lockbytes) = @_;
    my ($b1, $b2) = unpack("CC", $lockbytes);
    my %acl = (
        blbits => {
            '3 (otp)' =>  $b1 & 1,
            '4_9'     => ($b1 >> 1) & 1,
            '10_15'   => ($b1 >> 2) & 1
        },
        plbits => {
             3 => ($b1 >> 3) & 1,
             4 => ($b1 >> 4) & 1,
             5 => ($b1 >> 5) & 1,
             6 => ($b1 >> 6) & 1,
             7 => ($b1 >> 7) & 1,
             8 =>  $b2 & 1,
             9 => ($b2 >> 1) & 1,
            10 => ($b2 >> 2) & 1,
            11 => ($b2 >> 3) & 1,
            12 => ($b2 >> 4) & 1,
            13 => ($b2 >> 5) & 1,
            14 => ($b2 >> 6) & 1,
            15 => ($b2 >> 7) & 1
        }
    );
    return \%acl;
}

# anticollision/selection as defined on M028634_MF0ICU1_Functional_Spec_V3.4.pdf 
sub select {
    my $self = shift;

    use bytes;
    my $uid = pack("C6", @{$self->uid});
    nfc_configure($self->reader->pdi, NDO_ACTIVATE_FIELD, 0);

    # Configure the CRC and Parity settings
    nfc_configure($self->reader->pdi, NDO_HANDLE_CRC, 0);
    nfc_configure($self->reader->pdi, NDO_HANDLE_PARITY, 1);
    nfc_configure($self->reader->pdi, NDO_EASY_FRAMING, 0); 
    nfc_configure($self->reader->pdi, NDO_AUTO_ISO14443_4, 0); 
    nfc_configure($self->reader->pdi, NDO_FORCE_ISO14443_A, 1); 

    # Enable field so more power consuming cards can power themselves up
    nfc_configure($self->reader->pdi, ,NDO_ACTIVATE_FIELD, 1);
    my $retry = 0;
    my $retrycnt = 0;
    do {
        if (my $resp = nfc_initiator_transceive_bits($self->reader->pdi, pack("C", MU_REQA), 7)) {
            my $cmd = pack("C2", MU_SELECT1, 0x20); # ANTICOLLISION of cascade level 1
            if ($resp = nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 2)) {
                my (@rb) = split(//, $resp);
                my $cuid = pack("C3", $rb[1], $rb[2], $rb[3]);
                if ($rb[0] == 0x88) { # define a constant for 0x88
                    $cmd = pack("C9", MU_SELECT1, 0x70, @rb); # SELECT of cascade level 1  
                    #my $crc = $self->crc($cmd);
                    iso14443a_crc_append($cmd, 7);
                    if ($resp = nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 9)) {
                        # we need to do cascade level 2
                        # first let's get the missing part of the uid
                        $cmd = pack("C2", MU_SELECT2, 0x20); # ANTICOLLISION of cascade level 2
                        if ($resp = nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 2)) {
                            @rb = split(//, $resp);
                            $cuid .= pack("C3", $rb[1], $rb[2], $rb[3]);
                            $cmd = pack("C9", MU_SELECT2, 0x70, @rb); # SELECT of cascade level 2
                            #my $crc = $self->crc($cmd);
                            iso14443a_crc_append($cmd, 7);
                            if ($resp = nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 9)) {
                                if ($uid == $cuid) {
                                    return 1;
                                } else {
                                    # HALT the unwanted tag
                                    $cmd = pack("C2", MU_HALT, 0x00);
                                    nfc_initiator_transceive_bytes($self->reader->pdi, $cmd, 2);
                                    $retry = 1;
                                    $retrycnt++;
                                }
                            } else {
                                $self->{_last_error} = "Select cascade level 2 failed";
                            }
                        } else {
                            $self->{_last_error} = "Anticollision cascade level 2 failed";
                        }
                    } else {
                        $self->{_last_error} = "Select cascade level 1 failed";
                    }
                }
            } else {
                    $self->{_last_error} = "Anticollision cascade level 1 failed";
            }
        } else {
            $self->{_last_error} = "Device doesn't respond to REQA";
        }
    } while ($retry-- and $retrycnt < 10); # fail if we are redoing the selection process for the tenth time
    $self->{_last_error} = "Max retrycount reached" if ($retrycnt >= 10);
    return 0;
}

1;
__END__
=head1 NAME

RFID::Libnfc::Tag::ISO14443A_106::ULTRA 
Specific implementation for mifare ultralight tags

=head1 SYNOPSIS

  use RFID::Libnfc;

  $tag = $r->connectTag(IM_ISO14443A_106);

  # so the 2-level cascade selection process as specified in M028634_MF0ICU1_Functional_Spec_V3.4.pdf 
  $tag->select()  


=head1 DESCRIPTION

  Base class for ISO14443A_106 compliant tags

=head2 EXPORT

None by default.

=head2 Exportable functions

=head1 METHODS

=over

=item read_block ( $block )

Returns the data contained within the block number $block

NOTE: read operations on ultrlight will return back 16 bytes,
even if a single block is 4 bytes wide.
Remember also about the "roll back" property described in chapter 6.6.4 of 
the spec document : M028634_MF0ICU1_Functional_Spec_V3.4.pdf
So , If you are reading one of the last three blocks, you will get data also from the 
first ones , since always 4 blocks are read.

(for instance. if you read block 15, you will get back data from 15, 1, 2 and 3)

=item write_block ( $block, $data )

Writes $data into $blocknum.
Remember that ultralight cards have 4byte blocks
so whatever you pass as $data will be truncated to 4 bytes

=item read_sector ( $sector, $data )

On ultralight token read_sector is only an alias for read_block
since on such cards 1 sector (called also 'page' within the specs)
is exactly 1 block

=item write_sector ( $sector, $data )

On ultralight token write_sector is only an alias for write_block
since on such cards 1 sector (called also 'page' within the specs)
is exactly 1 block

=item blocks ( )

Returns the number of blocks present on the card

=item sectors ( )

Returns the number of sectors present on the card

=item acl ( )

Returns a representation of the aclbits.
(boths page-locking bits and block-locking bits)

=item select ( )

implements the 2-level cascade selection process

=back

=head1 SEE ALSO

RFID::Libnfc::Tag::ISO14443A_106::ULTRA RFID::Libnfc::Tag::ISO14443A_106::4K
RFID::Libnfc::Tag::ISO14443A_106 RFID::Libnfc::Constants RFID::Libnfc 

**

  check also documentation for libnfc c library 
  [ http://www.libnfc.org/documentation/introduction ] 

**

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

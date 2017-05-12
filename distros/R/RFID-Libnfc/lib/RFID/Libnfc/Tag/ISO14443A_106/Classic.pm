package RFID::Libnfc::Tag::ISO14443A_106::Classic;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A_106);
use RFID::Libnfc qw(nfc_configure nfc_initiator_transceive_bytes print_hex);
use RFID::Libnfc::Constants;

our $VERSION = '0.13';

# Internal representation of TABLE 3 (M001053_MF1ICS50_rev5_3.pdf)
# the key are the actual ACL bits (C1 C2 C3) ,
# the value holds read/write condition for : KeyA, ACL, KeyB
# possible values for read and write conditions are :
#    0 - operation not possible
#    1 - operation possible using Key A
#    2 - operation possible using Key B
#    3 - operation possible using either Key A or Key B
#   
# for instance: 
#
#   3 => { A => [ 0, 2 ], ACL => [ 3, 2 ], B => [ 0, 2 ] },
#
#   means that when C1C2C3 is equal to 011 (3) and so we can :
#      - NEVER read keyA
#      - write keyA using KeyB
#      - read ACL with any key (either KeyA or KeyB)
#      - write ACL using KeyB
#      - NEVER read KeyB
#      - write KeyB using KeyB
my %trailer_acl = (
    #    | KEYA   R  W  | ACL      R  W  | KEYB   R  W   | 
    0 => { A => [ 0, 1 ], ACL => [ 1, 0 ], B => [ 1, 1 ] },
    1 => { A => [ 0, 1 ], ACL => [ 1, 1 ], B => [ 1, 1 ] },
    2 => { A => [ 0, 1 ], ACL => [ 1, 0 ], B => [ 1, 0 ] },
    4 => { A => [ 0, 2 ], ACL => [ 3, 0 ], B => [ 0, 2 ] },
    3 => { A => [ 0, 2 ], ACL => [ 3, 2 ], B => [ 0, 2 ] },
    5 => { A => [ 0, 0 ], ACL => [ 3, 2 ], B => [ 0, 0 ] },
    6 => { A => [ 0, 0 ], ACL => [ 3, 0 ], B => [ 0, 0 ] },
    7 => { A => [ 0, 0 ], ACL => [ 3, 0 ], B => [ 0, 0 ] }
);

# Internal representation of TABLE 4 (M001053_MF1ICS50_rev5_3.pdf)
# the key are the actual ACL bits (C1 C2 C3) ,
# the value holds read, write, increment and decrement/restore conditions for the datablock
# possible values for any operation are :
#    0 - operation not possible
#    1 - operation possible using Key A
#    2 - operation possible using Key B
#    3 - operation possible using either Key A or Key B
#
# for instance: 
#
#   4 => [ 3, 2, 0, 0 ],
#   
#   means that when C1C2C3 is equal to 100 (4) and so we can :
#       - read the block using any key (either KeyA or KeyB)
#       - write the block using KeyB
#       - never increment the block
#       - never decrement/restore the block
#
my %data_acl = (            # read, write, increment, decrement/restore/transfer
    0 => [ 3, 3, 3, 3 ],    #  A|B   A|B      A|B        A|B
    1 => [ 3, 0, 0, 3 ],    #  A|B   never    never      A|B
    2 => [ 3, 0, 0, 0 ],    #  A|B   never    never      never
    3 => [ 2, 2, 0, 0 ],    #  B     B        never      never
    4 => [ 3, 2, 0, 0 ],    #  A|B   B        never      never
    5 => [ 2, 0, 0, 0 ],    #  B     never    never      never
    6 => [ 3, 2, 2, 3 ],    #  A|B   B        B          A|B
    7 => [ 0, 0, 0, 0 ]     #  never never    never      never
);

sub init {
    my $self = shift;

    nfc_configure($self->{reader}->pdi, NDO_AUTO_ISO14443_4, 0);
    # XXX - EASY_FRAMING has been introduced since libnfc 1.4 and 
    #       and if enabled allows us to avoid sending the preamble 
    #       when initiating the communication
    # TODO - make it optional and continue supporting full raw-frame sending
    nfc_configure($self->{reader}->pdi, NDO_EASY_FRAMING, 1);
    $self->SUPER::init(@_);
}

sub read_block {
    my ($self, $block, $noauth) = @_;

    my $sector = $self->block2sector($block); # sort out the sector we are going to access

    # check the ack for this datablock
    my $acl = $self->acl($sector);
    my $step = ($sector < 32)?4:16;
    my $datanum = "data".($block % $step);
    if ($acl && $acl->{parsed}->{$datanum}) {
        unless (@{$acl->{parsed}->{$datanum}}[0]) {
            $self->{_last_error} = "ACL denies reads on sector $sector, block $block";
            return undef;
        }
    }

    # try to do authentication only if we have required keys loaded
    if (scalar(@{$self->{_keys}}) >= $sector && !$noauth) { 
        return undef unless 
            $self->unlock($sector, (@{$acl->{parsed}->{$datanum}}[0] == 2) ? MC_AUTH_B : MC_AUTH_A);
    }
    # XXX - we are using EASY_FRAMING now .. so no need for the preamble
    #my $initiator_exchange_data = pack("C5", 0xD4, 0x40, 0x01, MC_READ, $block);
    my $initiator_exchange_data = pack("C2", MC_READ, $block);
    if (my $resp = nfc_initiator_transceive_bytes($self->reader->pdi, $initiator_exchange_data, 2)) {
        return unpack("a16", $resp); 
    } else {
        $self->{_last_error} = "Error reading $sector, block $block"; # XXX - does libnfc provide any clue on the ongoing error?
    }
    return undef;
}

sub write_block {
    my ($self, $block, $data, $force) = @_;

    my $sector = $self->block2sector($block); # sort out the sector we are going to access

    my $tblock = $self->trailer_block($sector);
    # don't write on trailer blocks unless explicitly requested ($force is tru)
    if ($block == $tblock && !$force) { 
        $self->{_last_error} = "use the \$force Luke";
        return undef;
    }

    # check the ack for this datablock
    my $acl = $self->acl($sector);
    my $step = ($sector < 32)?4:16;
    my $datanum = sprintf("data%d" , (15-($tblock-$block))%3);
    if ($acl && $acl->{parsed}->{$datanum}) {
        unless (@{$acl->{parsed}->{$datanum}}[1]) {
            $self->{_last_error} = "ACL denies reads on sector $sector, block $block";
            return undef;
        }
    }

    # try to do authentication only if we have required keys loaded
    if (scalar(@{$self->{_keys}}) >= $sector) { 
        return undef unless
            $self->unlock($sector, (@{$acl->{parsed}->{$datanum}}[1] == 2) ? MC_AUTH_B : MC_AUTH_A);
    }

    # XXX - we are using EASY_FRAMING now .. so no need for the preamble
    #my $initiator_exchange_data = pack("C5a16", 0xD4, 0x40, 0x01, MC_WRITE, $block, $data);
    my $initiator_exchange_data = pack("C2a16", MC_WRITE, $block, $data);
    if (nfc_initiator_transceive_bytes($self->reader->pdi, $initiator_exchange_data, 2+16)) {
        return 1;
    } else {
        # XXX can libnfc provide more info about the failure?
        $self->{_last_error} = "Writing to block $block failed"; 
    } 
    return undef;
}


sub write_sector {
    my ($self, $sector, $data) = @_;

    my $tblock = $self->trailer_block($sector);
    my $nblocks = ($sector < 32) ? 4 : 16;
    my $firstblock = $tblock - $nblocks + 1;
    { 
        my $buffer = pack("a240", $data);
        my $offset = 0;
        for (my $block = $firstblock; $block < $tblock; $block++) {
            unless ($self->write_block($block, unpack("x${offset}a16", $buffer))) {
                $self->{_last_error} = "Errors writing to block $block";
                return undef;
            }
            $offset += 16;
        }
    }
    return 1;
}

sub read_sector {
    my ($self, $sector) = @_;
    my $tblock = $self->trailer_block($sector);
    my $nblocks = ($sector < 32) ? 4 : 16;
    my $data;
    my $acl = $self->acl($sector);

    return unless ($self->unlock($sector));
    for (my $i = $tblock+1-$nblocks; $i < $tblock; $i++) {
        my $step = ($sector < 32)?4:16;
        my $newdata = $self->read_block($i);
        unless (defined $newdata) {
            $self->{_last_error} = "read failed on block $i";
            return undef;
        }
        $data .= $newdata;
    }
    return $data;
}

sub unlock {
    my ($self, $sector, $keytype) = @_;
    my $tblock = $self->trailer_block($sector);

    $keytype = MC_AUTH_A unless ($keytype and ($keytype == MC_AUTH_A or $keytype == MC_AUTH_B));
    my $keyidx = ($keytype == MC_AUTH_A) ? 0 : 1;

    # XXX - we are using EASY_FRAMING now .. so no need for the preamble
    #my $initiator_exchange_data = pack("C5a6C4", 0xD4, 0x40, 0x01, $keytype, $tblock, $self->{_keys}->[$sector][$keyidx], @{$self->uid});
    my $initiator_exchange_data = pack("C2a6C4", $keytype, $tblock, $self->{_keys}->[$sector][$keyidx], @{$self->uid});
    return 1 if (defined nfc_initiator_transceive_bytes($self->reader->pdi, $initiator_exchange_data, 2+6+4));

    $self->{_last_error} = "Failed to authenticate on sector $sector (tblock:$tblock) with key " .
        sprintf("%x " x 6 . "\n", unpack("C6", $self->{_keys}->[$sector][$keyidx]));
        
    return 0;
}

sub acl {
    my ($self, $sector) = @_;
    my $tblock = $self->trailer_block($sector);

    if ($self->unlock($sector)) {
        # XXX - we are using EASY_FRAMING now .. so no need for the preamble
        #my $initiator_exchange_data = pack("C5", 0xD4, 0x40, 0x01, MC_READ, $tblock);
        my $initiator_exchange_data = pack("C2", MC_READ, $tblock);
        if (my $data = nfc_initiator_transceive_bytes($self->reader->pdi, $initiator_exchange_data, 2)) {
            return $self->_parse_acl(unpack("x6a4x6", $data));
        }
    }
    return undef;
}

# ACL decoding according to specs in M001053_MF1ICS50_rev5_3.pdf
sub _parse_acl {
    my ($self, $data) = @_;
    use bytes;
    my ($b1, $b2, $b3, $b4) = unpack("C4", $data);
    # TODO - extend to doublecheck using inverted flags (as suggested in the spec)
    my %acl = (
        bits => { 
            c1 => [
                ($b2 >> 4) & 1,
                ($b2 >> 5) & 1,
                ($b2 >> 6) & 1,
                ($b2 >> 7) & 1,
            ],
            c2 => [
                ($b3) & 1,
                ($b3 >> 1) & 1,
                ($b3 >> 2) & 1,
                ($b3 >> 3) & 1,
            ],
            c3 => [
                ($b3 >> 4) & 1,
                ($b3 >> 5) & 1,
                ($b3 >> 6) & 1,
                ($b3 >> 7) & 1,
            ]
        }
    );
    $acl{parsed} = {
        data0   =>    $data_acl{($acl{bits}->{c1}->[0] << 2) | ($acl{bits}->{c2}->[0] << 1) | ($acl{bits}->{c3}->[0])},
        data1   =>    $data_acl{($acl{bits}->{c1}->[1] << 2) | ($acl{bits}->{c2}->[1] << 1) | ($acl{bits}->{c3}->[1])},
        data2   =>    $data_acl{($acl{bits}->{c1}->[2] << 2) | ($acl{bits}->{c2}->[2] << 1) | ($acl{bits}->{c3}->[2])},
        trailer => $trailer_acl{($acl{bits}->{c1}->[3] << 2) | ($acl{bits}->{c2}->[3] << 1) | ($acl{bits}->{c3}->[3])}
    };

    return wantarray?%acl:\%acl;
}

# compute the trailer block number for a given sector
sub trailer_block {
    use integer; # force integer arithmetic to round divisions

    my ($self, $sector) = @_;
    if ($sector < 32) {
        return (($sector+1) * 4) -1;
    } else {
        return 127 + (($sector - 31) * 16);
    }
}

# number of blocks in the tag
sub blocks {
    croak("You need to extend this class defining the layout of the tag");
}

# number of sectors in the tag
sub sectors {
    croak("You need to extend this class defining the layout of the tag");
}

sub block2sector {
    my ($self, $block) = @_;
    use integer; # force integer arithmetic to round divisions
    if ($block < 128) { # small data blocks : 4 x 16 bytes
        return $block/4;
    } else { # big datablocks : 16 x 16 bytes
        return 32 + ($block - 128)/16;
    }
}

sub is_trailer_block {
    my ($self, $block) = @_;
    return (($block < 128 and $block%4 == 3) or $block%16 == 15) ? 1 : 0;
}

sub set_key {
    my ($self, $sector, $keyA, $keyB) = @_;
    $self->{_keys}->[$sector] = [$keyA, $keyB];
}

sub set_keys {
    my ($self, @keys) = @_;
    my $cnt = 0;
    foreach my $key (@keys) {
        if (ref($key) and ref($key) eq "ARRAY") {
            $self->set_key($cnt++, @$key[0], @$key[1]);
        } else {
            $self->set_key($cnt++, $key, $key);
        }
    }
}

sub load_keys {
    my ($self, $keyfile) = @_;
    ($self->{_last_error} = "$!") and return undef 
        unless(open(KEYFILE, $keyfile));
    my $data;
    my $cnt = 0;
    print "Loading keys from $keyfile" if ($self->{debug});
    while (read(KEYFILE, $data, 16)) {
        if ($self->is_trailer_block($cnt)) {
            my ($keyA, $keyB) = unpack("a6x4a6", $data);
            if ($self->{debug}) {
                print "A: " and print_hex($keyA);
                print "B: " and print_hex($keyB);
            }
            $self->set_key($self->block2sector($cnt), $keyA, $keyB);
        }
        $cnt++;
    }
    close(KEYFILE);

    return $self->{_keys};
}

1;

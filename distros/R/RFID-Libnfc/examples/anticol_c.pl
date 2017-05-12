#!/usr/bin/perl


use strict;
use Data::Dumper;
use RFID::Libnfc qw(:all);
use RFID::Libnfc::Constants;

$| = 1;

sub transceive_bytes {
    my ($pdi, $cmd, $len) = @_;
    print "T: ";
    print_hex($cmd, $len);
    if (my $resp = nfc_initiator_transceive_bytes($pdi, $cmd, $len)) {
        print "R: ";
        print_hex($resp, length($resp));
        return $resp;
    }
    return undef;
}

sub transceive_bits {
    my ($pdi, $cmd, $len) = @_;
    print "T: " and print_hex($cmd, $len);
    if (my $resp = nfc_initiator_transceive_bits($pdi, $cmd, $len)) {
        print "R: ";
        print_hex($resp, length($resp));
        return $resp;
    }
    return undef;
}

my $pdi = nfc_connect();
if ($pdi == 0) { 
    print "No device!\n"; 
    exit -1;
}
nfc_initiator_init($pdi); 

nfc_configure($pdi, NDO_ACTIVATE_FIELD, 0);

# Configure the CRC and Parity settings
nfc_configure($pdi, NDO_HANDLE_CRC, 0);
nfc_configure($pdi, NDO_HANDLE_PARITY, 1);
nfc_configure($pdi, NDO_EASY_FRAMING, 0);
nfc_configure($pdi, NDO_AUTO_ISO14443_4, 0);
nfc_configure($pdi, NDO_FORCE_ISO14443_A, 1);

# Enable field so more power consuming cards can power themselves up
nfc_configure($pdi, NDO_ACTIVATE_FIELD, 1);
my $cmd = pack("C", MU_REQA);
if (my $resp = transceive_bits($pdi, $cmd, 7)) {
    $cmd = pack("C2", MU_SELECT1, 0x20); # ANTICOLLISION of cascade level 1
    
    if ($resp = transceive_bytes($pdi, $cmd, 2)) {
        my (@rb) = unpack("C".length($resp), $resp);
        my $cuid = pack("C3", $rb[1], $rb[2], $rb[3]);
        if ($rb[0] == 0x88) { # define a constant for 0x88
            $cmd = pack("C9", MU_SELECT1, 0x70, @rb); # SELECT of cascade level 1  
            iso14443a_crc_append($cmd, 7);
            if ($resp = transceive_bytes($pdi, $cmd, 9)) {
                # we need to do cascade level 2
                # first let's get the missing part of the uid
                $cmd = pack("C2", MU_SELECT2, 0x20); # ANTICOLLISION of cascade level 2
                if ($resp = transceive_bytes($pdi, $cmd, 2)) {
                    @rb = unpack("C".length($resp), $resp);
                    $cuid .= pack("C3", $rb[1], $rb[2], $rb[3]);
                    $cmd = pack("C9", MU_SELECT2, 0x70, @rb); # SELECT of cascade level 2
                    iso14443a_crc_append($cmd, 7);
                    if (transceive_bytes($pdi, $cmd, 9)) {
                         print "2 level cascade anticollision/selection passed for uid : ";
                         print_hex($cuid, 6);
                    } else {
                        warn "Select cascade level 2 failed";
                    }
                } else {
                    warn "Anticollision cascade level 2 failed";
                }
            } else {
                warn "Select cascade level 1 failed";
            }
        }
    } else {
            warn "Anticollision cascade level 1 failed";
    }
} else {
    warn "Device doesn't respond to REQA";
}
exit 0;



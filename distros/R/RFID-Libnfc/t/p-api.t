# Before `make install' is performed this script should be runnable with `make
# test'. After `make install' it should work as `perl Libnfc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
use Data::Dumper;
BEGIN { use_ok('RFID::Libnfc::Reader') };
use RFID::Libnfc::Constants ':all';

#########################


my $r;
eval {
    $r = RFID::Libnfc::Reader->new();
} or warn "No device! Skipping tests\n" and exit; 

if (ok ($r->init())) {
    printf ("Reader: %s\n", $r->name);

    my $tag = $r->connect(IM_ISO14443A_106);

    if (ok $tag) {
        $tag->dump_info;
        my $type = $tag->type;
        ok ($type);
        if ($tag->can('set_keys')) {
            my @keys = (
                pack("C6", 0x00,0x00,0x00,0x00,0x00,0x00),
                pack("C6", 0xb5,0xff,0x67,0xcb,0xa9,0x51),
            );

            $tag->set_keys(@keys);
            is (scalar(@{$tag->{_keys}}), 2);
        }
        my $data = $tag->read_block(0);
        is (length($data), 16);
        $data = $tag->read_sector(0);
        if ($type eq '4K') {
            is (length($data), 48);
        } elsif ($type eq 'ULTRA') {
            is (length($data), 16);
        }
        # try reading some data


        # todo complete testunit
    }
}

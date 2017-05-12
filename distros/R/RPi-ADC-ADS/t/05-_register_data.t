use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

my %mux = (
    # bit 14-12 (most significant bit shown)
    4 => 0x0,    # 00000000, 0
    5 => 0x1000, # 00100000, 4096
    6 => 0x2000, # 00100000, 8192
    7 => 0x3000, # 00110000, 12288
    8 => 0x4000, # 01000000, 16384
    1 => 0x5000, # 01010000, 20480
    2 => 0x6000, # 01100000, 24576
    3 => 0x7000, # 01110000, 28672

    0 => 0x4000, # 01000000, 16384, 100
    1 => 0x5000, # 01010000, 20480, 101
    2 => 0x6000, # 01100000, 24576, 110
    3 => 0x7000, # 01110000, 28672, 111
);

my %queue = (
    # bit 1-0 (least significant bit shown)
    0 => 0x00, # 00000000, 0
    1 => 0x01, # 00000001, 1
    2 => 0x02, # 00000010, 2
    3 => 0x03, # 00000011, 3
);

my %polarity = (
    # bit 3
    0 => 0x00, # 00000000, 0
    1 => 0x08, # 00000001, 8
);

my %rate = (
    # bit 7-5
    0 => 0x00, # 00000000, 0
    1 => 0x20, # 00100000, 32
    2 => 0x40, # 01000000, 64
    3 => 0x60, # 01100000, 96
    4 => 0x80, # 10000000, 128
    5 => 0xA0, # 10100000, 160
    6 => 0xC0, # 00000001, 192
    7 => 0xE0, # 00000001, 224
);


my %mode = (
    # bit 8
    0 => 0x00,  # 0|00000000, 0
    1 => 0x100, # 1|00000000, 256
);

my %gain = (
    # bit 11-9 (most significant bit shown)
    0 => 0x00,  # 00000000, 0
    1 => 0x200, # 00000010, 512
    2 => 0x400, # 00000100, 1024
    3 => 0x600, # 00000110, 1536
    4 => 0x800, # 00001000, 2048
    5 => 0xA00, # 00001010, 2560
    6 => 0xC00, # 00001100, 3072
    7 => 0xE00, # 00001110, 3584
);

{ # mux

    my $o = $mod->new;
    my $d = $o->_register_data->{mux};

    print "mux...\n";

    for (keys %$d){
        is $d->{$_}, $mux{$_}, "value for $_ ok";
    }
}

{ # queue

    my $o = $mod->new;
    my $d = $o->_register_data->{queue};

    print "\nqueue...\n";

    for (keys %$d){
        is $d->{$_}, $queue{$_}, "value for $_ ok";
    }
}

{ # polarity

    my $o = $mod->new;
    my $d = $o->_register_data->{polarity};

    print "\npolarity...\n";

    for (keys %$d){
        is $d->{$_}, $polarity{$_}, "value for $_ ok";
    }
}

{ # rate

    my $o = $mod->new;
    my $d = $o->_register_data->{rate};

    print "\nrate...\n";

    for (keys %$d){
        is $d->{$_}, $rate{$_}, "value for $_ ok";
    }
}

{ # mode

    my $o = $mod->new;
    my $d = $o->_register_data->{mode};

    print "\nmode...\n";

    for (keys %$d){
        is $d->{$_}, $mode{$_}, "value for $_ ok";
    }
}

{# polarity

    my $o = $mod->new;
    my $d = $o->_register_data->{polarity};

    print "\npolarity...\n";

    for (keys %$d){
        is $d->{$_}, $polarity{$_}, "value for $_ ok";
    }
}

done_testing();

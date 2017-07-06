use warnings;
use strict;

use LWP::Simple;
use RPi::LCD;
use RPi::WiringPi::Constant qw(:all);

my $lcd = RPi::LCD->new;


while (1){
    $lcd->init(%{ _lcd_args() });
    $lcd->position(0, 0);
    select(undef, undef, undef, 0.3);
}

sub _lcd_args {
    return {
        cols => 16,
        rows => 2,
        bits => 4,
        rs => 5,
        strb => 6,
        d0 => 4,
        d1 => 17,
        d2 => 27,
        d3 => 22,
        d4 => 0,
        d5 => 0, 
        d6 => 0, 
        d7 => 0,
    };
}


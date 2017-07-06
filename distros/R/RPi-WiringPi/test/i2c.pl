use warnings;
use strict;

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

my $lcd = $pi->lcd;
$lcd->init(%{_lcd_args()});

my $uno = $pi->i2c(0x04);

while (1){
    my @bytes = $uno->read_block(2, 80);
    my $output = ($bytes[0] << 8) | $bytes[1];

    my $volts = $output * (5.0 / 1024.0);
    $volts = sprintf("%.4f", $volts);
    print "output: $output, volts: $volts\n";

    $lcd->clear;
    $lcd->position(0, 0);
    $lcd->print("level: $output");
    $lcd->position(0, 1);
    $lcd->print("volts: $volts");

    sleep 5;
}
sub _lcd_args {
    return {
        rows => 2,
        cols => 16,
        bits => 4,
        rs   => 5,
        strb => 6,
        d0   => 4,
        d1   => 17,
        d2   => 27,
        d3   => 22,
        d4   => 0,
        d5   => 0,
        d6   => 0,
        d7   => 0,
    };
}

$pi->cleanup;


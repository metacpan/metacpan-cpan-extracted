use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

use constant ARDUINO_ADDR => 0x04;
use constant MAX_BYTES => 4;

my $mod = 'RPi::WiringPi';

BEGIN {
    if (! $ENV{RPI_ARDUINO}){
        plan skip_all => "RPI_ARDUINO environment variable not set\n";
    }

    if (! $ENV{PI_BOARD}){
        $ENV{NO_BOARD} = 1;
        plan skip_all => "Not on a Pi board\n";
    }
}

my $pi = $mod->new;

my $uno = $pi->i2c(ARDUINO_ADDR);

isa_ok $uno, 'RPi::I2C';

{ # read()
    $uno->write_byte(0, 0x00);
    is $uno->read, 0, "I2C read() ok";
}

{ # read_byte()
    is $uno->read_byte(5), 5, "I2C read_byte() ok";
}

{ # read_block()
    my @bytes = $uno->read_block(2, 10);
    my $num = ($bytes[0] << 8) | $bytes[1];
    is $num, 1023, "I2C read_block() ok"
}

select(undef, undef, undef, 0.2);

{ # write()
    $uno->write(25);
    my @data = _eeprom();
    is $data[0], 25, "I2C write() ok";
}

select(undef, undef, undef, 0.2);

{ # write_byte()
    $uno->write_byte(96, 30);
    my @data = _eeprom();
    is $data[0], 96, "I2C write_byte() ok";
}

select(undef, undef, undef, 0.2);

{ # write_block()
    my @send = qw(5 10 15 20);

    $uno->write_block(\@send, 35);

    my @data = _eeprom();

    my $c = 0;

    for (@data){
        is $_ == $send[$c], 1, "I2C write_block() block $c ok";
        $c++;
    }
}

sub _eeprom {
    my @bytes = $uno->read_block(MAX_BYTES, 99);
    return @bytes;
}

$pi->cleanup;

check_pin_status();

done_testing();

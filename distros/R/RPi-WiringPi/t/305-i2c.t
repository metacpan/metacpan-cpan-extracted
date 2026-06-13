use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

use constant ARDUINO_ADDR => 0x04;
use constant MAX_BYTES => 4;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

BEGIN {
    if (! $ENV{RPI_ARDUINO}){
        plan skip_all => "RPI_ARDUINO environment variable not set\n";
    }
}

my $pi = $mod->new(label => 't/305-i2c.t', shm_key => 'rpit');
# Belt-and-braces: if an assertion or library call dies mid-run, release the
# pins/registration this object holds (the library END reap is best-effort)

END { $pi->cleanup if $pi && ! $pi->{clean}; }


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

# The write tests poll the Arduino-side eeprom readback (bounded) until it
# reflects the write, instead of fixed settle windows before each block

{ # write()
    $uno->write(25);
    my @data = _poll_eeprom(sub { $_[0] == 25 });
    is $data[0], 25, "I2C write() ok";
}

{ # write_byte()
    $uno->write_byte(96, 30);
    my @data = _poll_eeprom(sub { $_[0] == 96 });
    is $data[0], 96, "I2C write_byte() ok";
}

{ # write_block()
    my @send = qw(5 10 15 20);

    $uno->write_block(\@send, 35);

    my @data = _poll_eeprom(sub {
        my @got = @_;

        return 0 if @got != @send;

        for my $i (0 .. $#send){
            return 0 if $got[$i] != $send[$i];
        }

        return 1;
    });

    my $c = 0;

    for (@data){
        is $_ == $send[$c], 1, "I2C write_block() block $c ok";
        $c++;
    }
}

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

sub _eeprom {
    my @bytes = $uno->read_block(MAX_BYTES, 99);
    return @bytes;
}
sub _poll_eeprom {
    my ($cond) = @_;

    # Poll the eeprom (bounded ~2s) until $cond->(@bytes) is true, returning
    # the final read either way; the caller's assertions still run in full

    my @bytes;

    for (1 .. 40){
        @bytes = _eeprom();
        last if $cond->(@bytes);
        select(undef, undef, undef, 0.05);
    }

    return @bytes;
}

use strict;
use warnings;

use Test::More;
use RPi::SPI;

# HW-free coverage. The accessor/routing/validation cases run against a bare
# blessed object (never new(), which would open the SPI bus). The rw() framing
# cases stub the WiringPi::API transport funcs imported into RPi::SPI and assert
# the sequence of hardware calls, so no bus or wiring is needed.

my $mod = 'RPi::SPI';

# --- _channel routing: 0/1 are hardware CE, above 1 is a GPIO chip select ---
{
    my $s = bless {}, $mod;
    is $s->_channel(0), 0, '_channel(0): hardware CE0';
    ok ! defined $s->_cs, '  channel 0: no GPIO CS';
}
{
    my $s = bless {}, $mod;
    is $s->_channel(1), 1, '_channel(1): hardware CE1';
    ok ! defined $s->_cs, '  channel 1: no GPIO CS';
}
{
    my $s = bless {}, $mod;
    is $s->_channel(26), 0, '_channel(26): GPIO CS routes to hardware channel 0';
    is $s->_cs, 26, '  GPIO 26 recorded as the CS';
}

# --- _cs round-trip ---
{
    my $s = bless {}, $mod;
    is $s->_cs(19), 19, '_cs(19): set';
    is $s->_cs, 19, '_cs(): get round-trips';
}

# --- _speed default + F13 fix ---
{
    my $s = bless {}, $mod;
    is $s->_speed, 1000000, '_speed(): defaults to 1MHz when unset';
    is $s->_speed(500000), 500000, '_speed(500000): honored';
}
{
    # F13: an explicit invalid speed now croaks instead of silently becoming 1MHz
    my $s = bless {}, $mod;

    eval { $s->_speed(0) };
    like $@, qr/speed must be a positive integer/, 'F13: explicit speed 0 croaks';

    eval { $s->_speed(-1) };
    like $@, qr/speed must be a positive integer/, 'speed -1 croaks';

    eval { $s->_speed('fast') };
    like $@, qr/speed must be a positive integer/, 'non-numeric speed croaks';
}

# --- _bitbang pin validation ---
{
    my $s = bless {}, $mod;

    for my $missing (qw(clk mosi miso cs)){
        my %pins = (clk => 21, mosi => 20, miso => 19, cs => 26);
        delete $pins{$missing};
        eval { $s->_bitbang({ %pins }) };
        like $@, qr/bit-bang mode requires an integer '$missing'/,
            "bit-bang: missing $missing croaks";
    }

    eval { $s->_bitbang({ clk => 'x', mosi => 20, miso => 19, cs => 26 }) };
    like $@, qr/requires an integer 'clk'/, 'bit-bang: non-integer pin croaks';
}
{
    my $s = bless {}, $mod;
    my $bb = $s->_bitbang({ clk => 21, mosi => 20, miso => 19, cs => 26 });
    is $bb->{mode}, 0, 'bit-bang: mode defaults to 0';
    is $bb->{delay}, 0, 'bit-bang: delay defaults to 0';
}

# --- rw() arg validation ---
{
    my $s = bless {}, $mod;

    eval { $s->rw(undef, 2) };
    like $@, qr/requires \$buf as an array reference/, 'rw(): undef buf croaks';

    eval { $s->rw('notaref', 2) };
    like $@, qr/requires \$buf as an array reference/, 'rw(): non-arrayref buf croaks';

    eval { $s->rw([1, 2], 0) };
    like $@, qr/requires \$len as a positive integer/, 'rw(): len 0 croaks';

    eval { $s->rw([1, 2], 'x') };
    like $@, qr/requires \$len as a positive integer/, 'rw(): non-integer len croaks';
}

# --- rw() framing via stubbed transport funcs ---
{
    no warnings 'redefine';

    my @calls;
    local *RPi::SPI::spiDataRW    = sub { push @calls, ['spiDataRW', $_[0]]; return @{$_[1]} };
    local *RPi::SPI::spiNoCS      = sub { push @calls, ['spiNoCS', $_[0], $_[1]] };
    local *RPi::SPI::digitalWrite = sub { push @calls, ['digitalWrite', $_[0], $_[1]] };
    local *RPi::SPI::spiBitBang   = sub { push @calls, ['spiBitBang', @_[0 .. 3]]; return @{$_[4]} };

    {
        @calls = ();
        my $s = bless { channel => 0 }, $mod;
        $s->rw([0x01, 0x02], 2);
        is_deeply \@calls, [['spiDataRW', 0]],
            'rw() plain hardware channel: spiDataRW only';
    }
    {
        @calls = ();
        my $s = bless { channel => 0, cs => 26, spi_no_cs => 1 }, $mod;
        $s->rw([0x01], 1);
        is_deeply \@calls, [
            ['spiNoCS', 0, 1],
            ['digitalWrite', 26, 0],
            ['spiDataRW', 0],
            ['digitalWrite', 26, 1],
            ['spiNoCS', 0, 0],
        ], 'rw() GPIO-CS (SPI_NO_CS supported): isolate + frame + de-isolate';
    }
    {
        @calls = ();
        my $s = bless { channel => 0, cs => 26, spi_no_cs => 0 }, $mod;
        $s->rw([0x01], 1);
        is_deeply \@calls, [
            ['digitalWrite', 26, 0],
            ['spiDataRW', 0],
            ['digitalWrite', 26, 1],
        ], 'rw() GPIO-CS (no SPI_NO_CS): CS framing only, no spiNoCS';
    }
    {
        @calls = ();
        my $s = bless {
            bitbang => { clk => 21, mosi => 20, miso => 19, cs => 26, mode => 0, delay => 0 },
        }, $mod;
        $s->rw([0x01], 1);
        is_deeply $calls[0], ['spiBitBang', 21, 20, 19, 26],
            'rw() bit-bang: spiBitBang with the configured pins';
    }
}

done_testing();

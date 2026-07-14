package RPi::SPI;

use strict;
use warnings;

use Carp qw(croak);
use WiringPi::API qw(:wiringPi);

our $VERSION = '3.1802';

sub new {
    my ($class, $channel, $speed) = @_;

    my $self = bless {}, $class;

    $self->_speed($speed);

    # A hashref channel selects full software bit-bang mode; an integer
    # selects the hardware SPI engine (0/1 = hardware CE0/CE1, above 1 = a
    # GPIO chip select we drive ourselves while the hardware CE line is
    # held off with SPI_NO_CS where the platform supports it)

    if (ref $channel eq 'HASH'){
        $self->_bitbang($channel);
    }
    else {
        $self->_channel($channel);
    }

    if ($self->_bitbang){
        # Initialize the software SPI lines to their idle state: clock idle
        # low (mode 0), chip select high (deasserted), MOSI an output and
        # MISO an input

        my $bb = $self->_bitbang;

        pinMode($bb->{clk}, 1);
        digitalWrite($bb->{clk}, 0);
        pinMode($bb->{cs}, 1);
        digitalWrite($bb->{cs}, 1);
        pinMode($bb->{mosi}, 1);
        pinMode($bb->{miso}, 0);
    }
    else {
        # A GPIO chip select is an ordinary output we hold high until a
        # transfer frames it low

        if ($self->_cs){
            pinMode($self->_cs, 1);
            digitalWrite($self->_cs, 1);
        }

        if (wiringPiSPISetup($self->_channel, $self->_speed) < 0){
            die "couldn't establish communication on the SPI bus\n";
        }

        # Probe SPI_NO_CS support once. The Pi 5's RP1 SPI controller
        # rejects this mode bit ("unsupported mode bits 40"), so where it's
        # unavailable we drop back to plain GPIO framing: the hardware CE
        # line still strobes, but that's harmless unless a second device
        # shares CE0/CE1

        if ($self->_cs){
            my $ok = eval {
                spiNoCS($self->_channel, 1);
                spiNoCS($self->_channel, 0);
                1;
            };

            $self->_spi_no_cs($ok ? 1 : 0);

            if (! $ok){
                warn "RPi::SPI: SPI_NO_CS is unsupported on this platform; " .
                     "the GPIO chip select will run without isolating the " .
                     "hardware CE line\n";
            }
        }
    }

    return $self;
}
sub rw {
    my ($self, $buf, $len) = @_;

    if (! defined $buf || ref $buf ne 'ARRAY') {
        croak "RPi::SPI rw() requires \$buf as an array reference\n";
    }

    if (! defined $len || $len !~ /^\d+$/ || $len == 0) {
        croak "RPi::SPI rw() requires \$len as a positive integer\n";
    }

    if ($self->_bitbang){
        my $bb = $self->_bitbang;

        @$buf = spiBitBang(
            $bb->{clk},
            $bb->{mosi},
            $bb->{miso},
            $bb->{cs},
            $buf,
            $len,
            $bb->{mode},
            $bb->{delay},
        );
    }
    elsif ($self->_cs){
        # GPIO chip select: where the platform supports it, hold the hardware
        # CE line off with SPI_NO_CS so it never strobes a second device.
        # Either way, frame the transfer with our own GPIO

        my $iso = $self->_spi_no_cs;

        spiNoCS($self->_channel, 1) if $iso;
        digitalWrite($self->_cs, 0);
        @$buf = spiDataRW($self->_channel, $buf, $len);
        digitalWrite($self->_cs, 1);
        spiNoCS($self->_channel, 0) if $iso;
    }
    else {
        @$buf = spiDataRW($self->_channel, $buf, $len);
    }

    return @$buf;
}
sub _bitbang {
    my ($self, $bb) = @_;

    if (defined $bb){
        for my $pin (qw(clk mosi miso cs)){
            if (! defined $bb->{$pin} || $bb->{$pin} !~ /^-?\d+$/){
                croak "RPi::SPI bit-bang mode requires an integer '$pin' " .
                      "GPIO pin\n";
            }
        }

        $bb->{mode}  = 0 if ! defined $bb->{mode};
        $bb->{delay} = 0 if ! defined $bb->{delay};

        $self->{bitbang} = $bb;
    }

    return $self->{bitbang};
}
sub _channel {
    my ($self, $chan) = @_;

    if (defined $chan){
        if ($chan > 1){
            $self->_cs($chan);
            $self->{channel} = 0;
        }
        else {
            $self->{channel} = $chan;
        }
    }

    return $self->{channel};
}
sub _cs {
    my ($self, $cs) = @_;

    $self->{cs} = $cs if defined $cs;
    return $self->{cs};
}
sub _speed {
    my ($self, $speed) = @_;

    # An undefined speed means "use the default"; a defined speed must be a
    # positive integer. Reject an explicit 0/negative/non-numeric rather than
    # silently rewriting it to the 1MHz default (which hid caller mistakes)

    if (defined $speed) {
        if ($speed !~ /^\d+$/ || $speed == 0) {
            croak "RPi::SPI speed must be a positive integer (Hz)\n";
        }
        $self->{speed} = $speed;
    }

    return $self->{speed} || 1000000;
}
sub _spi_no_cs {
    my ($self, $state) = @_;
    $self->{spi_no_cs} = $state if defined $state;
    return $self->{spi_no_cs};
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::SPI - Communicate with devices over the Serial Peripheral Interface (SPI)
bus on Raspberry Pi

=head1 SYNOPSIS

    # channel 0 and 1 are the hardware SPI pins
    # CE0 and CE1

    my $spi = RPi::SPI->new(0);

    my $buf = [0x01, 0x02];
    my $len = 2;

    my @data = $spi->rw($buf, $len);

    # use a GPIO pin to expand the number of SPI
    # channels. The transfer still runs on the
    # hardware SPI engine, but the hardware CE line
    # is held off (SPI_NO_CS) and we drive this GPIO
    # as the CS. It must connect to the CS/SS pin on
    # the IC you're using

    $spi = RPi::SPI->new(26); # GPIO 26 is the CS

    # or run the whole bus in software on any GPIO
    # pins by passing a hashref of bit-bang params

    $spi = RPi::SPI->new({ clk => 21, mosi => 20, miso => 19, cs => 26 });

=head1 DESCRIPTION

This distribution provides you the ability to communicate with devices attached
to the channels on the Serial Peripheral Interface (SPI) bus. Although it was
designed for the Raspberry Pi, that's not a hard requirement, and it should work
on any Unix-type system that has support for SPI.

You can use the hardware SPI pins CE0 and CE1 on the Raspberry Pi, but if you
need more SPI slaves, you can hand us any GPIO pin as the chip select instead:
the transfer still runs on the hardware SPI engine, but we hold the hardware CE
line off with C<SPI_NO_CS> and frame the transaction with your GPIO, so the
onboard CE0/CE1 pins are left untouched. You can also run the entire bus in
software (bit-bang) on arbitrary GPIO pins.

=head1 METHODS

=head2 new

Instantiates a new L<RPi::SPI> instance, prepares a specific SPI bus channel for
use, then returns the object.

Parameters:

    $channel

The SPI bus channel to initialize.

Mandatory: Integer or hashref.

Integer C<0> for C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>, using the
hardware chip select pins (CE0/CE1). Send in any number above C<1> and we'll
treat it as a GPIO pin connected to the CS/SS pin of the IC: the transfer
still runs on the hardware SPI engine, but we set the kernel's C<SPI_NO_CS>
flag and drive that GPIO ourselves around each transaction, freeing up the
onboard hardware chip selects and leaving CE0/CE1 untouched.

Send in a hashref instead to run the whole bus in software (bit-bang) on
arbitrary GPIO pins (BCM numbering):

    my $spi = RPi::SPI->new({
        clk   => 21, # Clock
        mosi  => 20, # Data out (to the device), or -1 if unused
        miso  => 19, # Data in  (from the device), or -1 if unused
        cs    => 26, # Chip select, or -1 to manage it yourself
        mode  => 0,  # Optional SPI mode 0-3 (default 0)
        delay => 1,  # Optional microseconds per clock phase (default 0)
    });

    $speed

Optional, Integer. The data rate to communicate on the bus using. Defaults to
C<1000000> (1MHz). Ignored in bit-bang mode (use C<delay> to pace the clock).

Dies if we can't open the SPI bus.

=head2 rw

Writes specified data to the bus on the channel specified in C<new()>, then
after completion, does a read of the bus and re-populates the write buffer with
the freshly read data, and returns it as an array.

Parameters:

    $buf

Mandatory: Array reference where each element is an unsigned char (0-255). This
array is the write buffer; the data we'll be sending to the SPI bus.

    $len

Mandatory: Integer, the number of array elements in the C<$buf> parameter sent
in above.

Return: The write buffer, after being re-populated with the read data, as a Perl
array.

Dies if we can't open the SPI bus.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

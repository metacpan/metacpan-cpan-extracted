package RF::HC12;

use strict;
use warnings;

use Carp qw(croak);
use RPi::Serial;

our $VERSION = '0.01';

use constant {
    COMM_BAUD   => 9600,
    EOL         => 0x0A,
    DEBUG_FETCH => 0,
};

sub new {
    my ($class, $dev) = @_;

    croak "new() requires a serial device path sent in" if ! defined $dev;

    my $self = bless {}, $class;

    $self->_serial($dev, COMM_BAUD);

    return $self;
}
sub test {
    my ($self) = @_;
    my $cmd = 'AT';
    return $self->_fetch_control($cmd);
}
sub baud {
    my ($self, $baud) = @_;

    if (defined $baud){
        if (! $self->_baud_rates($baud)){
            croak "baud rate '$baud' is invalid. See the documentation";
        }
        my $cmd = "AT+B$baud";
        $self->_set_control($cmd);
    }
    return $self->_fetch_control('AT+RB');
}
sub power {
    my ($self, $tp) = @_;

    if (defined $tp){
        if (! $self->_power_rates($tp)){
            croak "transmit power '$tp' is invalid. See the documentation";
        }
        my $cmd = "AT+P$tp";
        $self->_set_control($cmd);
    }
    return $self->_fetch_control('AT+RP');
}
sub mode {
    my ($self, $mode) = @_;

    if (defined $mode){
        if (! grep {$mode == $_} (1, 2, 3)){
            croak "functional mode'$mode' is invalid. Values are 1, 2 or 3";
        }
        my $cmd = "AT+FU$mode";
        $self->_set_control($cmd);
    }
    return $self->_fetch_control('AT+RF');
}
sub version {
    my ($self) = @_;
    return $self->_fetch_control('AT+V');
}
sub channel {
    my ($self, $channel) = @_;

    if (defined $channel){
        if (! grep {$channel == $_} (1..127)){
            croak "channel '$channel' is invalid. Values are 1-127";
        }

        # pad out zeros to the left to make 3 chars
        my $pad = 3 - length($channel);
        $channel = 0 x $pad . $channel;

        my $cmd = "AT+C$channel";
        $self->_set_control($cmd);
    }
    return $self->_fetch_control('AT+RC');
}
sub config {
    my ($self) = @_;

    $self->_serial->puts('AT+RX');

    my ($read, $line_count);

    while (1){
        if ($self->_serial->avail){
            my $char = $self->_serial->getc;

            $read .= chr $char;
            if (hex(sprintf("%x", $char)) == 0x0A){
                $line_count++;
                return $read if $line_count == 4;
            }

        }
    }
}
sub reset {
    my ($self) = @_;
    $self->_fetch_control('AT+DEFAULT');
}
sub sleep {
    return $_[0]->_fetch_control('AT+SLEEP');
}
sub wake {
    return $_[0]->_fetch_control('AT');
}

sub _serial {
    my ($self, $dev, $comm_baud) = @_;
    return $self->{serial} if exists $self->{serial};
    $self->{serial} = RPi::Serial->new($dev, $comm_baud);
    return $self->{serial};
}
sub _set_control {
    my ($self, $control) = @_;
    $self->_serial->puts($control);
}
sub _fetch_control {
    my ($self, $control) = @_;

    $self->_serial->puts($control);

    my $read;

    while (1){
        if ($self->_serial->avail){
            my $char = $self->_serial->getc;

            if (hex(sprintf("%x", $char)) == 0x0D){
                next;
            }

            if (hex(sprintf("%x", $char)) == 0x0A){
                return $read;
            }

            $read .= chr $char;
        }
    }
}
sub _baud_rates {
    my ($self, $baud) = @_;

    my $baud_rates = {
        1200    => 1,
        2400    => 1,
        4800    => 1,
        9600    => 1,
        19200   => 1,
        38400   => 1,
        57600   => 1,
        115200  => 1,
    };

    return sort {$a <=> $b}(keys(%$baud_rates)) if ! defined $baud;

    return $baud_rates->{$baud} ? 1 : 0;
}
sub _power_rates {
    my ($self, $rate) = @_;

    my $power_rates = {
        1   => -1,
        2   => 2,
        3   => 5,
        4   => 8,
        5   => 11,
        6   => 14,
        7   => 17,
        8   => 20
    };

    return %$power_rates if ! defined $rate;
    return $power_rates->{$rate} ? 1 : 0;
}

1;
__END__

=head1 NAME

RF::HC12 - Interface to the 433 MHz HC-12 Radio Frequency serial trancievers

=head1 DESCRIPTION

Interfaces with the HC-12 433MHz Radio Frequency serial data transceivers.

B<NOTE>: Currently, this distribution can only be used to configure the devices,
in the future, I'll incorporate the ability to use it to actually communicate
between them.

B<NOTE>: The C<HC-12> transceivers are designed to operate in pairs. The
settings on one device must match the other device or communication will fail.

=head1 SYNOPSIS

    use RF::HC12;

    my $rf = RF::HC12->new('/dev/ttyUSB0');

    $rf->sleep;
    $rf->wake;

    print $rf->baud;
    print $rf->power;
    print $rf->mode;
    print $rf->channel;

    print $rf->config;

=head1 METHODS

=head2 new($device)

Instantiates a new L<RF::HC12> module over the serial interface, and returns
it.

Parameters:

    $device

Mandatory, String: The path and file name of your UART serial TTY device. (eg:
C</dev/ttyUSB0>).

=head2 test

Sends a test command to the HC-12 transceiver. If everything is configured
correctly, this method will return the string C<OK>.

=head2 config

Returns all of the various configuration settings as they are currently set.
Here's an example containing the configuration of a unit set to factory
defaults:

    OK+B9600        # 9600 baud
    OK+RC001        # RF channel 001 (this is the min)
    OK+RP:+20dBm    # +20dBm power (this is the max)
    OK+FU3          # transmission mode

=head2 reset

Resets the HC-12 unit to factory defaults. See L</config> for details on what
the defaults are.

Return, String: C<OK+DEFAULT> on success.

=head2 baud($baud)

Set/get the baud rate of the HC-12.

Parameters:

    $baud

Optional, Integer: The baud rate that the HC-12 will communicate over. Valid
values:

    1200
    2400
    4800
    9600
    19200
    38400
    57600
    115200

Return, String: The current baud rate, eg. C<OK+B9600>.

=head2 channel($ch)

Sets/gets the channel the device operates on.

Parameters:

    $ch

Optional, Integer: The channel to operate under. Valid values are C<1> (default)
through C<127>. All channels above channel C<100> are likely to be flaky, so
unless you're testing or having communication problems using lower channels,
don't use them.

Return, String: The current operating channel, eg. C<OK+RC001>.

=head2 power($tp)

Sets/gets the transmission power (dB) of the HC-12.

Parameters:

    $tp

Optional, Integer: The associated mapping to the value to set. Valid values
(1-8):

    Param     Value (dB)
     1           -1
     2           2
     3           5
     4           8
     5           11
     6           14
     7           17
     8           20

Return, String: The current value, eg. C<OK+RP:+20dBm>.

=head2 mode($mode)

Sets/gets the transmission mode of the HC-12. This setting is transparent for
the most part, and relies on other settings. I'd recomment reading the
datasheet for the device before modifying this setting.

Parameters:

    $mode

Optional, Integer: The mode to set the device to. Valid values are C<1-3>.

Return, String: The current mode, eg. C<OK+FU3>.

=head2 sleep

Puts the HC-12 into a sleep mode. In this mode, no RF communication is possible,
and the device will operate at C<0.22 micro Amp> working current.

=head2 wake

The opposite of L</sleep>. Wakes the device back up for wireless communication.

=head2 version

Returns the current version information from the HC-12's firmware.

Example: C<www.hc01.com  HC-12_V2.4>.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

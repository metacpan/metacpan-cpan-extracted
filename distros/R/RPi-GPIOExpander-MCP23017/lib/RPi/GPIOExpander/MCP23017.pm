package RPi::GPIOExpander::MCP23017;

use strict;
use warnings;

use Carp qw(croak);
use RPi::Const qw(:all);

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('RPi::GPIOExpander::MCP23017', $VERSION);

use constant {
    BANK_A          => 0,
    BANK_B          => 1,
    REG_BITS_ON     => 0xFF,
    REG_BITS_OFF    => 0x00,
};

# operational methods

sub new {
    my ($class, $addr) = @_;
    my $self = bless {}, $class;
    $self->_fd(getFd($addr // 0x20));
    return $self;
}
sub cleanup {
    clean($_[0]->_fd);
}

# pin methods

sub mode {
    my ($self, $pin, $mode) = @_;

    if (! defined $mode){
        my $reg = $pin > 7 ? MCP23017_IODIRB : MCP23017_IODIRA;
        my $bit = _pinBit($pin);
        return getRegisterBit($self->_fd, $reg, $bit);
    }

    _check_mode($mode);

    pinMode($self->_fd, $pin, $mode);
}
sub pullup {
    my ($self, $pin, $state) = @_;

    if (! defined $state){
        my $reg = $pin > 7 ? MCP23017_GPPUB : MCP23017_GPPUA;
        my $bit = _pinBit($pin);
        return getRegisterBit($self->_fd, $reg, $bit);
    }

    _check_pullup($state);

    pullUp($self->_fd, $pin, $state);
}
sub read {
    my ($self, $pin) = @_;
    return readPin($self->_fd, $pin);
}
sub write {
    my ($self, $pin, $state) = @_;

    _check_write($state);

    return writePin($self->_fd, $pin, $state);
}

# bank methods

sub mode_bank {
    my ($self, $bank, $mode) = @_;

    _check_bank($bank);
    my $reg = $bank == BANK_A ? MCP23017_IODIRA : MCP23017_IODIRB;

    if (! defined $mode){
        return getRegister($self->_fd, $reg);
    }

    _check_mode($mode);
    $mode = REG_BITS_ON if $mode == MCP23017_INPUT;

    setRegister($self->_fd, $reg, $mode, "mode_bank()");

    return getRegister($self->_fd, $reg);
}
sub write_bank {
    my ($self, $bank, $state) = @_;

    _check_bank($bank);
    _check_write($state);

    my $reg = $bank == BANK_A ? MCP23017_GPIOA : MCP23017_GPIOB;
    $state = REG_BITS_ON if $state == HIGH;

    setRegister($self->_fd, $reg, $state, "write_bank()");

    return getRegister($self->_fd, $reg);
}
sub pullup_bank {
    my ($self, $bank, $state) = @_;

    _check_bank($bank);

    my $reg = $bank == BANK_A ? MCP23017_GPPUA : MCP23017_GPPUB;

    if (! defined $state){
        return getRegister($self->_fd, $reg);
    }

    _check_pullup($state);

    $state = REG_BITS_ON if $state == HIGH;

    setRegister($self->_fd, $reg, $state, "write_pullup()");

    return getRegister($self->_fd, $reg);
}

# both bank (all) methods

sub mode_all {
    my ($self, $mode) = @_;

    _check_mode($mode);
    $mode = REG_BITS_ON if $mode == MCP23017_INPUT;

    for my $reg (MCP23017_IODIRA .. MCP23017_IODIRB) {
        setRegister($self->_fd, $reg, $mode, "mode_all()");
    }
}
sub write_all {
    my ($self, $state) = @_;

    _check_write($state);
    $state = REG_BITS_ON if $state == HIGH;

    for my $reg (MCP23017_GPIOA .. MCP23017_GPIOB) {
        setRegister($self->_fd, $reg, $state, "write_all()");
    }
}
sub pullup_all {
    my ($self, $state) = @_;

    _check_pullup($state);
    $state = REG_BITS_ON if $state == MCP23017_INPUT;

    for my $reg (MCP23017_GPPUA .. MCP23017_GPPUB) {
        setRegister($self->_fd, $reg, $state, "mode_all()");
    }
}

# register methods

sub register {
    my ($self, $reg, $data) = @_;

    if (defined $data){
        setRegister($self->_fd, $reg, $data, 'register()');
    }
    return getRegister($self->_fd, $reg);
}
sub register_bit {
    my ($self, $reg, $bit) = @_;

    my $regval = getRegisterBit($self->_fd, $reg, $bit);
    return $regval;
}

# internal/helper methods

sub _check_bank {
    my ($bank) = @_;
    if ($bank != BANK_A && $bank != BANK_B){
        croak "bank param must be either 0 or 1, not '$bank'\n";
    }
}
sub _check_mode {
    my ($mode) = @_;
    if ($mode != MCP23017_INPUT && $mode != MCP23017_OUTPUT){
        croak "mode param must be either 0 or 1, not '$mode'\n";
    }
}
sub _check_pullup {
    my ($state) = @_;

    if ($state != HIGH && $state != LOW){
        croak "state param must be either 0 or 1, not '$state'\n";
    }
}
sub _check_write {
    my ($state) = @_;

    if (! defined $state){
        croak "write() requires the state to be sent in\n";
    }

    if ($state != HIGH && $state != LOW){
        croak "state param must be either 0 or 1, not '$state'\n";
    }
}
sub _fd {
    my ($self, $fd) = @_;
    $self->{fd} = $fd if defined $fd;
    return $self->{fd};
}

1;
__END__

=head1 NAME

RPi::GPIOExpander::MCP23017 - Interface to the MCP23017 GPIO Expander Integrated
Circuit over I2C

=head1 DESCRIPTION

This distribution allows you to interface with an MCP23017 (i2c based
communication) GPIO expander chip. It provides 16 GPIO digital pins.

There are two "banks" of pins, bank C<0> (A) and bank C<1> (B). Each bank
contains eight pins.

Pins can be accessed/modified individually, by bank, or all at once.

In this initial distribution, not all of the chip's functionality is included,
but the core functionality is. In upcoming releases, we'll add the remaining
functionality, particularly interrupts.

=head1 SYNOPSIS

    use RPi::GPIOExpander::MCP23017;

    my $mcp23017_i2c_addr = 0x20;

    my $exp = RPi::GPIOExpander::MCP23017->new($mcp_i2c_addr);

    # pins are INPUT by default. Turn the first pin to OUTPUT

    $exp->mode(0, 0); # or MCP23017_OUTPUT if using RPi::Const

    # turn the pin on (HIGH)

    $exp->write(0, 1); # or HIGH

    # read the pin's status (HIGH or LOW)

    $exp->read(6);

    # turn the first bank (0) of pins (0-7) to OUTPUT, and make them live (HIGH)

    $exp->mode_bank(0, 0);  # bank A, OUTPUT
    $exp->write_bank(0, 1); # bank A, HIGH

    # enable internal pullup resistors on the entire bank A (0)

    $exp->pullup_bank(0, 1); # bank A, pullup enabled

    # put all 16 pins as OUTPUT, and put them on (HIGH)

    $exp->mode_all(0);  # or OUTPUT
    $exp->write_all(1); # or HIGH

    # cleanup all pins and reset them to default before exiting your program

    $exp->cleanup;

=head1 OPERATIONAL METHODS

=head2 new($addr)

Instantiates and returns a new L<RPi::GPIOExpander::MCP23017> object.

Parameters:

    $addr

Optional, Integer: The I2C address of the device. Defaults to C<0x20>.

=head2 cleanup

Resets the device registers back to their original startup configuration.

=head1 PIN METHODS

The pins on the expander are arranged in two banks. Bank C<A> (ie. C<0> in code)
are pins C<0> through C<7>. Bank C<B> (ie. C<1> in code) contains pins C<8>
through C<15>.

The first argument to these individual pin methods is the pin number (C<0-15>),
the second is the argument to instruct what you want the pin to do.

=head2 read($pin)

Fetches the current state of the pin, on or off (HIGH or LOW).

Parameters:

    $pin

Mandatory, Integer: The pin number, C<0-15>.

Return: Bool. C<1> for on (HIGH), C<0> for off (LOW).

=head2 mode($pin, [$mode])

Allows toggling of a pin between input and output mode.

Parameters:

    $pin

Mandatory, Integer: The pin number, C<0-15>.

    $mode

Optional, Bool: C<0> for output, C<1> for input. If using L<RPi::Const>, these
equate to C<MCP23017_OUTPUT> and C<MCP23017_INPUT>. Default startup of the IC is
input.

Return: Bool. C<1> for input (MCP23017_INPUT), C<0> for output
(MCP23017_OUTPUT).

=head2 write($pin, $state)

Turns an output pin on (HIGH) or off (LOW). Will only have effect if the pin is
in output mode.

Parameters:

    $pin

Mandatory, Integer: The pin number, C<0-15>.

    $state

Mandatory, Bool: C<0> for off (LOW), C<1> for on (HIGH).

Return: None (void function).

=head2 pullup($pin, [$state])

The MCP23017 only has pull-up resistors (ie. there's no pull-downs). This method
allows you to toggle the state of the pullup resistor.

Parameters:

    $pin

Mandatory, Integer: The pin number, C<0-15>.

    $state

Optional, Bool: C<0> for off (LOW), C<1> for on (HIGH).

Return: Bool. C<1> if the pullup is enabled, and C<0> if not.

=head1 BANK METHODS

The following methods deal with pin "banks". There are two banks of pins on the
device, bank C<A> (represented as C<0> here), and bank C<B> (represented as
C<1>)

These methods will act on an entire bank of pins. Bank 0 (A) consists of pins
C<0-7> whereas bank 1 (B) encompasses pins C<8-15>.

=head2 mode_bank($bank, [$mode])

This method will set the mode for the eight pins associated with the specified
bank in one fell swoop.

Parameters:

    $bank

Mandatory, Integer: C<0> for bank A (pins 0-7) or C<1> for bank B (pins 8-15).

    $mode

Optional, Integer: C<0> (or C<MCP23017_OUTPUT>) for output mode, or C<1> (or
C<MCP23017_INPUT> for input mode. The default mode on device startup is input
for all pins.

Return: Ingeter. A byte containing the state of the entire bank's mode register.

=head2 write_bank($bank, $state)

This method will write the operational state (on/off aka high/low) for an entire
bank of pins. Has no effect for pins that are currently in INPUT mode.

Parameters:

    $bank

Mandatory, Integer: C<0> for bank A (pins 0-7) or C<1> for bank B (pins 8-15).

    $state

Mandatory, Bool: C<0> (or C<LOW>) for off, or C<1> (or C<HIGH>) for on.

=head2 pullup_bank($bank, [$state])

Allows you to enable or disable the built-in pull-up resistors for an entire
bank of pins all at the same time.

Parameters:

    $bank

Mandatory, Integer: C<0> for bank A (pins 0-7) or C<1> for bank B (pins 8-15).

    $state

Mandatory, Bool: C<0> (or C<LOW>) to disable the pullups, or C<1> (or C<HIGH>)
to enable them.

Return: Ingeter. A byte containing the state of the entire bank's pullup
register.

=head1 ALL PIN METHODS

The following methods allows you to act on all pins across both banks in one
fell swoop.

=head2 mode_all($mode)

This method allows you to set the mode (input or output) on all 16 pins at the
same time.

Parameters:

    $mode

Mandatory, Integer: C<0> (or C<MCP23017_OUTPUT>) for output mode, or C<1> (or
C<MCP23017_INPUT> for input mode. The default mode on device startup is input
for all pins.

=head2 write_all($state)

This method will write the operational state (on/off aka high/low) for all 16
pins at the same time. Has no effect for pins that are currently in INPUT mode.

Parameters:

    $state

Mandatory, Bool: C<0> (or C<LOW>) for off, or C<1> (or C<HIGH>) for on.

=head2 pullup_all($state)

Allows you to enable or disable the built-in pull-up resistors for all 16 pins
at the same time.

Parameters:

    $state

Mandatory, Bool: C<0> (or C<LOW>) to disable the pullups, or C<1> (or C<HIGH>)
to enable them.

=head1 REGISTER ACCESS METHODS

These methods provide you direct access to the device registers themselves. They
are here for convenience only, and really shouldn't be used unless you are
familiar with the registers and how they operate.

=head2 register($register, [$data]);

Gets and or sets the specified register.

Parameters:

    $register

Mandatory, Integer: The register to read and or write.

    $data

Optional, Integer: A single byte to enable/disable bits in the specified
register.

Return: Integer, the value of the register specified.

=head2 register_bit($register, $bit)

Allows you to read a single bit from within the specified register.

Parameters:

    $register

Mandatory, Integer: The register to read the bit from.

    $bit

Mandatory, Integer: The bit to read from the given register. Valid values are
C<0> through C<7>.

Return: Bool, C<0> if the bit is not set, and C<1> if it is.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


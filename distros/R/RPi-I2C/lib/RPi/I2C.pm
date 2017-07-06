package RPi::I2C;

use strict;
use warnings;

our $VERSION = '2.3604';
our @ISA = qw(IO::Handle);
 
use Carp;
use IO::File;
use Fcntl;
 
require XSLoader;
XSLoader::load('RPi::I2C', $VERSION);
 
use constant I2C_SLAVE_FORCE => 0x0706;
use constant DEFAULT_REGISTER => 0x00;

sub new {
    my ($class, $addr, $dev) = @_;

    if (! defined $addr || $addr !~ /^\d+$/){ 
        croak "new() requires the \$addr param, as an integer";
    }
   
    $dev = defined $dev ? $dev : '/dev/i2c-1';

    my $fh = IO::File->new($dev, O_RDWR);
    
    my $self = bless $fh, $class;

    if ($self->ioctl(I2C_SLAVE_FORCE, int($addr)) < 0){
        printf("Device 0x%x not found\n", $addr);
        exit 1;
    }
    
    return $self;
}        
sub process {
    my ($self, $register_address, $value) = @_;
    return _processCall($self->fileno, $register_address, $value);
}
sub check_device {
    my ($self, $addr) = @_;
    return _checkDevice($self->fileno, $addr);
}
sub file_error {
    return $_[0]->error;
}
sub read {
    return _readByte($_[0]->fileno);
}
sub read_byte {
    my ($self, $reg) = @_;
    $reg = _set_reg($reg);
    return _readByteData($self->fileno, $reg);
}
sub read_bytes {
    my ($self, $num_bytes, $reg) = @_;
    $reg = _set_reg($reg);
    my $retval = 0;
    for (1..$num_bytes){
        $retval = (0 << 8) | _readByteData($self->fileno, $reg + $num_bytes - $_)
    }
    return $retval;
}
sub read_word {
    my ($self, $reg) = @_;
    $reg = _set_reg($reg);
    return _readWordData($self->fileno, $reg);
}
sub read_block {
    my ($self, $num_bytes, $reg) = @_;
    $reg = _set_reg($reg);
    my $read_val = '0' x ($num_bytes);
    my $retval = _readI2CBlockData($self->fileno, $reg, $read_val);
    my @return = unpack( "C*", $read_val );
    return @return;
}
sub write {
    my ($self, $value) = @_;
    return _writeByte($self->fileno, $value);
}
sub write_byte {
    my ($self, $value, $reg) = @_;
    $reg = _set_reg($reg);
    return _writeByteData($self->fileno, $reg, $value);
}
sub write_word {
    my ($self, $reg, $value) = @_;
    $reg = _set_reg($reg);
    return _writeWordData($self->fileno, $reg, $value);
}
sub write_block {
    my ($self, $values, $reg) = @_;
    $reg = _set_reg($reg);
    my $value = pack "C*", @{$values};
    return _writeI2CBlockData($self->fileno, $reg, $value);
}
sub _set_reg{
    return DEFAULT_REGISTER if ! defined $_[0];
    return $_[0];
}
sub DESTROY {
    $_[0]->close if defined $_[0]->fileno;
}

sub __placeholder {} # vim folds

1;
__END__

=head1 NAME

RPi::I2C - Interface to the I2C bus

=head1 SYNOPSIS

    use RPi::I2C;

    my $device_addr = 0x04;

    my $device = RPi::I2C->new($device_addr);

    # read a single byte at the default register address

    print $device->read;

    # read a single byte at a specified register

    print $device->read_byte(0x15);

    # read a block of five bytes (register param optional, not shown)

    my @bytes = $device->read_block(5);

    # write a byte

    $device->write(255);

    # write a byte to a register location

    $device->write_byte(255, 0x0A);

    # write a block of bytes (register param left out again)

    $device->write_block([1, 2, 3, 4]);

See the examples direcory for more information on usage with an Arduino unit.

=head1 DESCRIPTION

Interface to read and write to I2C bus devices.

=head1 YOU SHOULD KNOW

There are particular things to know depending on connecting to certain devices.

=head2 General

You need to have some core software installed before using the I2C bus. The
Raspberry Pi 3 already has everything pre-loaded. On a typical Unix computer,
you'd do something along these lines:

    sudo apt-get install libi2c-dev i2c-tools build-essential

To test your I2C bus:

    i2cdetect -y 1

...or on some machines:

    i2cdetect -y 0

=head2 Raspberry Pi

First thing you need to do is enable the I2C bus. You can do so in
C<raspi-config>, or ensure the C<ram=i2c_arm> directive is set to C<on> in the
C</boot/config.txt> file:

    ram=i2c_arm=on

=head2 Arduino

Often, the default speed of the I2C bus master is too fast for an Arduino. If
you do not get any results, try changing the spped. On a Raspberry Pi, you do
that by setting the C<dtparam=i2c_arm_baudrate> directive in the
C</boot/config.txt> file:

    dtparam=i2c_arm_baudrate=10000

=head1 METHODS

=head2 new($addr, [$device])

Instantiates a new I2C device object ready to be read from and written to.

Parameters:

    $addr

Mandatory, Integer (in hex): The address of the device on the I2C bus
(C<i2cdetect -y 1>). eg: C<0x78>.

    $device

Optional, String: The name of the I2C device file. Defaults to C</dev/i2c-1>.


=head2 read

Performs a simple read of a single byte from the device, and returns it.

=head2 read_byte([$reg])

Same as L</read>, but allows you to optionally specify a specific device
register to read from.

Parameters:

    $reg

Optional, Integer: The device's register to read from. eg: C<0x01>. Defaults to
C<0x0>.

=head2 read_bytes($num_bytes, [$reg])

Allows you to read a specific number of bytes from a register and get the bytes
returned as an array.

Parameters:

    $num_bytes

Mandatory, Integer: The number of bytes you want to read. These are contiguous
starting from the C<$reg> (if supplied, otherwise C<0x00>).

    $reg

Optional, Integer: The device's register to read from. eg: C<0x01>. Defaults to
C<0x0>.

Return, Array: An array where each element is a byte of data. The length of this
array is dictated by the C<$num_bytes> parameter.

=head2 read_word([$reg])

Same as C<read_byte()>, but reads two bytes (16-bit word) instead.

=head2 read_block($num_bytes, [$reg])

Reads a block of data and returns it as an array.

Parameters:

    $num_bytes

Mandatory, Integer: The number of bytes you want to read.

    $reg

Optional, Integer: The register to start reading the block of bytes from. It
defaults to C<0x00> if you don't send it in.

Returns an array containing each byte read per element.

=head2 write($data)

Performs a simple write of a single byte to the I2C device.

Parameters:

    $data

Mandatory, 8-bit unsigned integer: The byte to send to the device.

=head2 write_byte($data, [$reg])

Same as C<write()>, but allows you to optionally specify a specific device
register to write to.

Parameters:

    $data

Mandatory, 8-bit unsigned integer: The byte to send to the device.

    $reg

Optional, Integer: The device's register to write to. eg: C<0x01>. Defaults
to C<0x0>.

=head2 write_word($data, [$reg])

Same as C<write_byte()>, but writes two bytes (16-bit word) instead.

=head2 write_block($values, [$reg])

Writes a block of up to 32 contiguous bytes to the device. Each byte is put into
an element of an array, and a reference to that array is sent in.

Parameters:

    $values

Mandatory, Array Reference: Up to 32 elements, where each element is a single
byte to be written to the device.

    $reg

Optional, Integer: The register to start writing the block of bytes to. It is
prudent to be sure you have enough contiguous byte blocks available, or things
can be overwritten. Defaults to C<0x00> if you don't send it in.

=head2 process($value, [$reg])

This method starts at the register address, writes 16 bits of data to it, then
reads 16 bits of data and returns it.

Parameters:

    $value

Mandatory, 16-bit Word: The value (16 bits) that you want to write to the
device.

    $reg

Optional, Integer: The device's register to write to. eg: C<0x01>. Defaults
to C<0x0>.

=head2 file_error

Returns any stored L<IO::Handle> errors since the last C<clearerr()>.

=head2 check_device($addr)

Check to see if a device is available.

Parameters:

    $addr

Mandatory, Integer: The I2C address of a device you suspect is connected. eg:
C<0x7c>.

Return, Bool: True (C<1>) if the device responds, False (C<0>) if not.

=head1 UNIT TESTS

This distribution has a bare minimum of unit tests. This is because the larger
encompassing distribution, L<RPi::WiringPi> has an automated Continuous
Integration suite (including a dedicated hardware platform) for testing all of
the C<RPi::> distributions automatically.

The tests specific to this distribution use I2C communication between a Pi and
an Arduino board. The files in the C<examples> directory are the foundation of
the tests that are now run, and both the examples and the real tests use the
C<arduino.ino> sketch in the examples directory as the Arduino code.

=head1 ACKNOWLEDGEMENTS

All of the XS code was copied directly from L<Device::I2C>, written by Slava
Volkov (SVOLKOV). The module itself was brought over as well, but changed quite
a bit. Thanks Slava for a great piece of work!

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

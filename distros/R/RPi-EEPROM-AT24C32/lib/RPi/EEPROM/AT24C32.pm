package RPi::EEPROM::AT24C32;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::EEPROM::AT24C32', $VERSION);

use constant {
    ADDR_MIN_VALUE => 0,
    ADDR_MAX_VALUE => 4095,
    BYTE_MIN_VALUE => 0,
    BYTE_MAX_VALUE => 255
};

sub new {
    my ($class, %args) = @_;

    $args{device}  //= '/dev/i2c-1';
    $args{address} //= 0x57;
    $args{delay}   //= 1;

    my $self = bless {%args}, $class;

    my $fd = eeprom_init($args{device}, $args{address}, $args{delay});
    $self->fd($fd);

    return $self;
}
sub fd {
    my ($self, $fd) = @_;
    $self->{fd} = $fd if defined $fd;
    return $self->{fd};
}
sub read {
    my ($self, $addr) = @_;
    _check_addr('read', $addr);
    return eeprom_read($self->fd, $addr);
}
sub write {
    my ($self, $addr, $byte) = @_;

    _check_addr('write', $addr);
    _check_byte('write', $byte);

    return eeprom_write($self->fd, $addr, $byte);
}
sub _check_addr {
    my ($sub, $addr) = @_;

    croak "_check_addr() requires \$sub param...\n" if ! defined $sub;

    if (! defined $addr){
        croak "$sub requires an EEPROM memory address sent in...\n";
    }

    if ($addr < ADDR_MIN_VALUE || $addr > ADDR_MAX_VALUE){
        croak "address parameter out of range. Must be between " .
              ADDR_MIN_VALUE . " and " . ADDR_MAX_VALUE . "\n";
    }

    return 1;
}
sub _check_byte {
    my ($sub, $byte) = @_;

    croak "_check_byte() requires \$sub param...\n" if ! defined $sub;

    if (! defined $byte){
        croak "$sub requires a data byte sent in...\n";
    }

    if ($byte < BYTE_MIN_VALUE || $byte > BYTE_MAX_VALUE){
        croak "data byte parameter out of range. Must be between " .
              BYTE_MIN_VALUE . " and " . BYTE_MAX_VALUE . "\n";
    }

    return 1;
}

1;
__END__

=head1 NAME

RPi::EEPROM::AT24C32 - Read and write to the AT24C32 based EEPROM ICs

=head1 DESCRIPTION

Read and write data to the AT24C32-based EEPROM Integrated Circuits.

Currently, only the actual AT24C32 that has 4096 8-bit address locations
(C<0-4095>).

It'll work for the AT24C64 unit as well, but only half of the address space will
be available. I'll update this after I get one of these units.

=head1 SYNOPSIS

    use RPi::EEPROM::AT24C32;

    my $eeprom = RPi::EEPROM::AT24C32->new(
        device  => '/dev/i2c-1', # optional, default
        address => 0x57,         # optional, default
        delay   => 1             # optional, default
    );

    # write to, and read from a block of EEPROM addresses in a loop

    my $value = 1;

    for my $memory_address (200..225){
        $eeprom->write($memory_address, $value);
        print $eeprom->read($memory_address) . "\n";
        $value++;
    }

=head1 METHODS

=head2 new(%args)

Instantiates a new L<RPi::EEPROM::AT24C32> object, initializes the i2c bus,
and returns the object.

Parameters:

All parameters are sent in as a hash.

    device => '/dev/i2c-1'

Optional, String. The name of the i2c bus device to use. Defaults to
C</dev/i2c-1>.

    address => 0x57

Optional, Integer. The i2c address of the EEPROM device. Defaults to C<0x57>.

    delay => 1

Optional, Integer. Due to issues on the Raspberry Pi's i2c ability to "clock
stretch" the bus, with some devices a slight delay (milliseconds) must be used
between write cycles. This parameter is the multiplier for said write cycle
timer.

If you're frequently getting write or I/O errors when performing multiple
write/reads in succession, bump this number up.

Defaults to C<1>.

=head2 read($addr)

Performs a single-byte read of the EEPROM storage from the specified memory
location.

Parameters:

    $addr

Mandatory, Integer. Valid values are C<0-4095>.

Return: The byte value located within the specified EEPROM memory register.

=head2 write($addr, $byte)

Writes a single 8-bit byte of data to the EEPROM memory address specified.

Parameters:

    $addr

Mandatory, Integer. Valid values are C<0-4095>.

    $byte

Mandatory, Integer. Valid values are C<0-255>.

Return: C<0> on success, C<-1> on failure.

=head1 ACCESSORY METHODS

These are methods that aren't normally required for the use of this software,
but may be handy for troubleshooting or future purposes.

=head2 fd($fd)

Sets/gets the file descriptor that our i2c initialization routine assigned to
us.

Parameters:

    $fd

Optional, Integer: This is set internally, and it would be very unwise to set it
manually at any other time.

Return: The file descriptor (integer) that the C<ioctl()> initialization
routine assigned us.

=head1 PRIVATE METHODS

=head2 _check_addr

Ensures that the EEPROM memory register address supplied as a parameter is
within limits.

=head2 _check_byte

For write calls, ensures that the data byte supplied is within valid limits.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Steve Bertrand.

GPL version 2+ (due to using modified GPL'd code).

1; # End of RPi::EEPROM::AT24C32

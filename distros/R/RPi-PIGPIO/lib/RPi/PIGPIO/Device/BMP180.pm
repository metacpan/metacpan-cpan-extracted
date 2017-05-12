package RPi::PIGPIO::Device::BMP180;

=head1 NAME

RPi::PIGPIO::Device::BMP180 - Read temperature and atmospheric pressure from a BMP180 sensor

=head1 DESCRIPTION

Uses the pigpiod to read temperature and atmospheric pressure from a BMP180 sensor

=head1 SYNOPSIS

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::BMP180;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $bmp180 = RPi::PIGPIO::Device::BMP180->new($pi,1);

    $bmp180->read_sensor(); #trigger a read

    print "Temperature : ".$bmp180->temperature." C\n";
    print "Presure : ".$bmp180->presure." mbar\n";

=cut

use strict;
use warnings;

use Carp;
use RPi::PIGPIO ':all';

use Time::HiRes qw/usleep/;

use constant {  # Register Addresses
  REG_CALIB  => 0xAA,
  REG_MEAS   => 0xF4,
  REG_MSB    => 0xF6,
  REG_LSB    => 0xF7,
  # Control Register Address
  CRV_TEMP   => 0x2E,
  CRV_PRES   => 0x34,
};

# Oversample setting
my $OVERSAMPLE = 3;    # 0 - 3

=head1 METHODS

=head2 new

Create a new object

Usage:

    my $bmp180 = RPi::PIGPIO::Device::BMP180->new($pi,$spi,$address);

Arguments: 

=over 4

=item * $pi - an instance of RPi::PIGPIO

=item * $spi - SPI to which the sensor is connected (defaults to 1)

=item * $address - address of the sensor (defaults to 0x77)

=back

=cut
sub new {
    my ($class,$pi,$spi,$address) = @_;
    
    $spi //= 1;
    $address //= 0x77;
    
    if (! $pi || ! ref($pi) || ref($pi) ne "RPi::PIGPIO") {
        croak "new expectes the first argument to be a RPi::PIPGIO object!";
    }
    
    my $self = {
        pi => $pi,
        spi => $spi,
        address => $address,
        temperature => undef,
        humidity => undef,
        chip_id => undef,
        chip_version => undef,
    };
    
    bless $self, $class;
    
    $self->read_sensor();
    
    return $self;
}


=head2 read_sensor

Trigger a read from the sensor. You need to call this method whenever you want to 
get the latest values

Usage :

    $bmp180->read_sensor();

    print "Presure : ".$bmp180->presure()." mbar";

=cut
sub read_sensor {
    my ($self) = @_;
    
    my $pi = $self->{pi};
    
    my $handle = $pi->i2c_open($self->{spi}, $self->{address});
    
    # We only need to read the chip id once
    if (! defined $self->{chip_id}) {
        my (undef, $response) = $pi->i2c_read_i2c_block_data($handle, 0xD0,2);
    
        $self->{chip_id} = $response->[0];
        $self->{chip_version} = $response->[1];
    }
    
    # Read the calibration data
    my (undef, $data) = $pi->i2c_read_i2c_block_data($handle, REG_CALIB, 22);
    
    # Convert byte data to word values
    my $AC1 = compile_calibration_info($data, 0);
    my $AC2 = compile_calibration_info($data, 2);
    my $AC3 = compile_calibration_info($data, 4);
    my $AC4 = compile_unsigned_calibration_info($data, 6);
    my $AC5 = compile_unsigned_calibration_info($data, 8);
    my $AC6 = compile_unsigned_calibration_info($data, 10);
    my $B1  = compile_calibration_info($data, 12);
    my $B2  = compile_calibration_info($data, 14);
    my $MB  = compile_calibration_info($data, 16);
    my $MC  = compile_calibration_info($data, 18);
    my $MD  = compile_calibration_info($data, 20);
    
    # Read the temperature
    $pi->i2c_write_byte_data($handle, REG_MEAS, CRV_TEMP);
    usleep(5);
    my (undef, $temp_data) = $pi->i2c_read_i2c_block_data($handle, REG_MSB, 2);
    
    my $UT = ($temp_data->[0] << 8) + $temp_data->[1];
    
    # Refine temperature
    my $X1 = (($UT - $AC6) * $AC5) >> 15;
    my $X2 = int(ensure_c_long($MC << 11) / ($X1 + $MD));
    my $B5 = $X1 + $X2;
  
    my $temperature = int($B5 + 8) >> 4;

    $self->{temperature} = $temperature/10;
    
    # Read the atmosferic pressure
    $pi->i2c_write_byte_data($handle, REG_MEAS, CRV_PRES + ($OVERSAMPLE << 6));
    usleep(40);
    my (undef, $presure_data) = $pi->i2c_read_i2c_block_data($handle, REG_MSB, 3);
    
    my $UP = (($presure_data->[0] << 16) + ($presure_data->[1] << 8) + $presure_data->[2]) >> (8 - $OVERSAMPLE);
  
    # Refine pressure
    my $B6  = $B5 - 4000;
    my $B62 = int($B6 * $B6) >> 12;
    $X1  = ($B2 * $B62) >> 11;
    $X2  = int($AC2 * $B6) >> 11;
    my $X3  = $X1 + $X2;
    my $B3  = ((($AC1 * 4 + $X3) << $OVERSAMPLE) + 2) >> 2;

    $X1 = int($AC3 * $B6) >> 13;
    $X2 = ($B1 * $B62) >> 16;
    $X3 = (($X1 + $X2) + 2) >> 2;
    my $B4 = ($AC4 * ($X3 + 32768)) >> 15;
    my $B7 = ($UP - $B3) * (50000 >> $OVERSAMPLE);

    my $P = ($B7 * 2) / $B4;

    $X1 = (int($P) >> 8) * (int($P) >> 8);
    $X1 = ($X1 * 3038) >> 16;
    $X2 = ensure_c_short(int(-7357 * $P) >> 16);
    my $pressure = ensure_c_long($P + (($X1 + $X2 + 3791) >> 4));
    
    $self->{pressure} = $pressure/100;

    $pi->i2c_close($handle);    
}

=head2 pressure

Returns the atmospheric pressure in mbar

=cut
sub pressure { return $_[0]->{pressure}; }

=head2 temperature

Returns the temperature in C

=cut
sub temperature { return $_[0]->{temperature}; }

=head2 chip_id

Returns the chip id

=cut
sub chip_id { return $_[0]->{chip_id}; }

=head2 chip_version

Returns the chip version

=cut
sub chip_version { return $_[0]->{chip_version}; }


=head1 PRIVATE METHODS

=head2 compile_calibration_info

Return an signed int from after putting together 2 consecutive values from the calibration data

=cut
sub compile_calibration_info {
    my ($data, $start_pos) = @_;
    
    my $val = unpack("s",pack("s",($data->[$start_pos] << 8) + $data->[$start_pos+1]));

    return $val;
}

=head2 compile_unsigned_calibration_info

Return an unsigned int from after putting together 2 consecutive values from the calibration data

=cut
sub compile_unsigned_calibration_info {
    my ($data, $start_pos) = @_;
    
    my $val = unpack("S",pack("S", ($data->[$start_pos] << 8) + $data->[$start_pos+1]));
    
    return $val;
}

=head2 ensure_c_long

Make sure the given number is a C signed long value (32 bit)

=cut
sub ensure_c_long {
    return unpack('l',pack('l',$_[0]));
}

=head2 ensure_c_short

Make sure the given number is a C signed short value (16 bit)

=cut
sub ensure_c_short {
    return unpack('s',pack('s',$_[0]));
}

1;
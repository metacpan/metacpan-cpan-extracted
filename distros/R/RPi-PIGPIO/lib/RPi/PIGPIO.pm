package RPi::PIGPIO;

=head1 NAME

RPi::PIGPIO - remotely control the GPIO on a RaspberryPi using the pigpiod daemon

=head1 DESCRIPTION

This module impements a client for the pigpiod daemon, and can be used to control 
the GPIO on a local or remote RaspberryPi

On every RapberryPi that you want to use you must have pigpiod daemon running!

You can download pigpiod from here L<http://abyz.co.uk/rpi/pigpio/download.html>

=head2 SYNOPSYS

Blink a led connecyed to GPIO17 on the RasPi connected to the network with ip address 192.168.1.10

    use RPi::PIGPIO ':all';

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    $pi->set_mode(17, PI_OUTPUT);

    $pi->write(17, HI);

    sleep 3;

    $pi->write(17, LOW);

Easier mode to controll leds / switches :

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::LED;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $led = RPi::PIGPIO::Device::LED->new($pi,17);

    $led->on;

    sleep 3;

    $led->off;

Same with a switch (relay):

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::Switch;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $switch = RPi::PIGPIO::Device::Switch->new($pi,4);

    $switch->on;

    sleep 3;

    $switch->off;

Read the temperature and humidity from a DHT22 sensor connected to GPIO4

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::DHT22;

    my $dht22 = RPi::PIGPIO::Device::DHT22->new($pi,4);

    $dht22->trigger(); #trigger a read

    print "Temperature : ".$dht22->temperature."\n";
    print "Humidity : ".$dht22->humidity."\n";

=head1 ALREADY IMPLEMENTED DEVICES

Note: you can write your own code using methods implemeted here to controll your own device

This is just a list of devices for which we already implemented some functionalities to make your life easier

=head2 Generic LED 

See complete documentations here: L<RPi::PIGPIO::Device::LED>

Usage:

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::LED;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $led = RPi::PIGPIO::Device::LED->new($pi,17);

    $led->on;

    sleep 3;

    $led->off;


=head2 Seneric switch / relay

See complete documentations here: L<RPi::PIGPIO::Device::Switch>

Usage:

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::Switch;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $switch = RPi::PIGPIO::Device::Switch->new($pi,4);

    $switch->on;

    sleep 3;

    $switch->off;

=head2 DHT22 temperature/humidity sensor

See complete documentations here : L<RPi::PIGPIO::Device::DHT22>

Usage:

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::DHT22;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $dht22 = RPi::PIGPIO::Device::DHT22->new($pi,4);

    $dht22->trigger(); #trigger a read

    print "Temperature : ".$dht22->temperature."\n";
    print "Humidity : ".$dht22->humidity."\n";


=head2 BMP180 atmospheric presure/temperature sensor

See complete documentations here : L<RPi::PIGPIO::Device::BMP180>

Usage:

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::BMP180;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $bmp180 = RPi::PIGPIO::Device::BMP180->new($pi,1);

    $bmp180->read_sensor(); #trigger a read

    print "Temperature : ".$bmp180->temperature." C\n";
    print "Presure : ".$bmp180->presure." mbar\n";

=head2 DSM501A dust particle concentraction sensor

See complete documentations here : L<RPi::PIGPIO::Device::DSM501A>

Usage:
    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::DSM501A;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $dust_sensor = RPi::PIGPIO::Device::DSM501A->new($pi,4);

    # Sample the air for 30 seconds and report
    my ($ratio, $mg_per_m3, $pcs_per_m3, $pcs_per_ft3) = $dust_sensor->sample();

=head2 MH-Z14 CO2 module

See complete documentations here: L<RPi::PIGPIO::Device::MH_Z14>

Usage:
    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::MH_Z14;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $co2_sensor = RPi::PIGPIO::Device::MH_Z14->new($pi,mode => 'serial', tty => '/dev/ttyAMA0');

    $ppm = $co2_sensor->read();


=head2 MCP3008/MCP3004 analog-to-digital convertor

See complete documentations here: L<RPi::PIGPIO::Device::ADC::MCP300x>

Usage:
    use feature 'say';
    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::ADC::MCP300x;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $mcp = RPi::PIGPIO::Device::ADC::MCP300x->new(0);

    say "Sensor 1: " .$mcp->read(0);
    say "Sensor 2: " .$mcp->read(1);

=back

=cut

use strict;
use warnings;

our $VERSION     = '0.017';

use Exporter 5.57 'import';

use Carp;
use IO::Socket::INET;
use Package::Constants;

use constant {
    PI_INPUT  => 0,
    PI_OUTPUT => 1,
    PI_ALT0   => 4,
    PI_ALT1   => 5,
    PI_ALT2   => 6,
    PI_ALT3   => 7,
    PI_ALT4   => 3,
    PI_ALT5   => 2,

    HI           => 1,
    LOW          => 0,

    RISING_EDGE  => 0,
    FALLING_EDGE => 1,
    EITHER_EDGE  => 2,
    
    PI_PUD_OFF  => 0,
    PI_PUD_DOWN => 1,
    PI_PUD_UP   => 2,
};

use constant {
    PI_CMD_MODES => 0,
    PI_CMD_MODEG => 1,
    PI_CMD_PUD   => 2,
    PI_CMD_READ  => 3,
    PI_CMD_WRITE => 4,
    PI_CMD_PWM   => 5,
    PI_CMD_PRS   => 6,
    PI_CMD_PFS   => 7,
    PI_CMD_SERVO => 8,
    PI_CMD_WDOG  => 9,
    PI_CMD_BR1   => 10,
    PI_CMD_BR2   => 11,
    PI_CMD_BC1   => 12,
    PI_CMD_BC2   => 13,
    PI_CMD_BS1   => 14,
    PI_CMD_BS2   => 15,
    PI_CMD_TICK  => 16,
    PI_CMD_HWVER => 17,

    PI_CMD_NO => 18,
    PI_CMD_NB => 19,
    PI_CMD_NP => 20,
    PI_CMD_NC => 21,

    PI_CMD_PRG   => 22,
    PI_CMD_PFG   => 23,
    PI_CMD_PRRG  => 24,
    PI_CMD_HELP  => 25,
    PI_CMD_PIGPV => 26,

    PI_CMD_WVCLR => 27,
    PI_CMD_WVAG  => 28,
    PI_CMD_WVAS  => 29,
    PI_CMD_WVGO  => 30,
    PI_CMD_WVGOR => 31,
    PI_CMD_WVBSY => 32,
    PI_CMD_WVHLT => 33,
    PI_CMD_WVSM  => 34,
    PI_CMD_WVSP  => 35,
    PI_CMD_WVSC  => 36,

    PI_CMD_TRIG => 37,

    PI_CMD_PROC  => 38,
    PI_CMD_PROCD => 39,
    PI_CMD_PROCR => 40,
    PI_CMD_PROCS => 41,

    PI_CMD_SLRO => 42,
    PI_CMD_SLR  => 43,
    PI_CMD_SLRC => 44,

    PI_CMD_PROCP => 45,
    PI_CMD_MICRO => 46,
    PI_CMD_MILLI => 47,
    PI_CMD_PARSE => 48,

    PI_CMD_WVCRE => 49,
    PI_CMD_WVDEL => 50,
    PI_CMD_WVTX  => 51,
    PI_CMD_WVTXR => 52,
    PI_CMD_WVNEW => 53,

    PI_CMD_I2CO  => 54,
    PI_CMD_I2CC  => 55,
    PI_CMD_I2CRD => 56,
    PI_CMD_I2CWD => 57,
    PI_CMD_I2CWQ => 58,
    PI_CMD_I2CRS => 59,
    PI_CMD_I2CWS => 60,
    PI_CMD_I2CRB => 61,
    PI_CMD_I2CWB => 62,
    PI_CMD_I2CRW => 63,
    PI_CMD_I2CWW => 64,
    PI_CMD_I2CRK => 65,
    PI_CMD_I2CWK => 66,
    PI_CMD_I2CRI => 67,
    PI_CMD_I2CWI => 68,
    PI_CMD_I2CPC => 69,
    PI_CMD_I2CPK => 70,

    PI_CMD_SPIO => 71,
    PI_CMD_SPIC => 72,
    PI_CMD_SPIR => 73,
    PI_CMD_SPIW => 74,
    PI_CMD_SPIX => 75,

    PI_CMD_SERO  => 76,
    PI_CMD_SERC  => 77,
    PI_CMD_SERRB => 78,
    PI_CMD_SERWB => 79,
    PI_CMD_SERR  => 80,
    PI_CMD_SERW  => 81,
    PI_CMD_SERDA => 82,

    PI_CMD_GDC => 83,
    PI_CMD_GPW => 84,

    PI_CMD_HC => 85,
    PI_CMD_HP => 86,

    PI_CMD_CF1 => 87,
    PI_CMD_CF2 => 88,

    PI_CMD_NOIB => 99,

    PI_CMD_BI2CC => 89,
    PI_CMD_BI2CO => 90,
    PI_CMD_BI2CZ => 91,

    PI_CMD_I2CZ => 92,

    PI_CMD_WVCHA => 93,

    PI_CMD_SLRI => 94,

    PI_CMD_CGI => 95,
    PI_CMD_CSI => 96,

    PI_CMD_FG => 97,
    PI_CMD_FN => 98,

    PI_CMD_WVTXM => 100,
    PI_CMD_WVTAT => 101,

    PI_CMD_PADS => 102,
    PI_CMD_PADG => 103,

    PI_CMD_FO    => 104,
    PI_CMD_FC    => 105,
    PI_CMD_FR    => 106,
    PI_CMD_FW    => 107,
    PI_CMD_FS    => 108,
    PI_CMD_FL    => 109,
    PI_CMD_SHELL => 110,
    
    PI_CMD_BSPIC => 112, # bbSPIClose
    PI_CMD_BSPIO => 134, # bbSPIOpen
    PI_CMD_BSPIX => 193, # bbSPIXfer
};


# notification flags
use constant {
    NTFY_FLAGS_ALIVE => (1 << 6),
    NTFY_FLAGS_WDOG  => (1 << 5),
    NTFY_FLAGS_GPIO  => 31,
};


our @EXPORT_OK   = Package::Constants->list( __PACKAGE__ );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

=head1 METHODS

=head2 connect

Connects to the pigpiod running on the given IP address/port and returns an object
that will allow us to manipulate the GPIO on that Raspberry Pi

Usage:

    my $pi = RPi::PIGPIO->connect('127.0.0.1');

Arguments:

=over 4

=item * arg1: ip_address - The IP address of the pigpiod daemon

=item * arg2: port - optional, defaults to 8888

=back 

Note: The pigiod daemon must be running on the raspi that you want to use

=cut
sub connect {
    my ($class,$address,$port) = @_;
    
    $port ||= 8888;
    
    my $sock = IO::Socket::INET->new(
                        PeerAddr => $address,
                        PeerPort => $port,
                        Proto    => 'tcp'
                        );

    my $pi = {
        sock => $sock,
        host => $address,
        port => $port,
    };
    
    bless $pi, $class;
}


=head2 connected

Returns true is we have an established connection with the remote pigpiod daemon

=cut
sub connected {
    my $self = shift;
    
    return $self->{sock} && $self->{sock}->connected();
}


=head2 disconnect

Disconnect from the gpiod daemon.

The current object is no longer usable once we disconnect.

=cut
sub disconnect {
    my $self = shift;
    
    $self->prepare_for_exit();
    
    undef $_[0];
}

=head2 get_mode

Returns the mode of a given GPIO pin

Usage : 

    my $mode = $pi->get_mode(4);

Arguments:

=over 4

=item * arg1: gpio - GPIO for which you want to change the mode

=back

Return values (constant exported by this module):

    0 = PI_INPUT
    1 = PI_OUTPUT
    4 = PI_ALT0
    5 = PI_ALT1
    6 = PI_ALT2
    7 = PI_ALT3
    3 = PI_ALT4
    2 = PI_ALT5

=cut
sub get_mode {
    my $self = shift;
    my $gpio = shift;
    
    die "Usage : \$pi->get_mode(<gpio>)" unless (defined($gpio));

    return $self->send_command(PI_CMD_MODEG,$gpio);
}

=head2 set_mode

Sets the GPIO mode

Usage: 

    $pi->set_mode(17, PI_OUTPUT);

Arguments :

=over 4

=item * arg1: gpio - GPIO for which you want to change the mode

=item * arg2: mode - the mode that you want to set. 
        Valid values for I<mode> are exported as constants and are : PI_INPUT, PI_OUTPUT, PI_ALT0, PI_ALT1, PI_ALT2, PI_ALT3, PI_ALT4, PI_ALT5

=back

Returns 0 if OK, otherwise PI_BAD_GPIO, PI_BAD_MODE, or PI_NOT_PERMITTED.

=cut

sub set_mode {
   my ($self,$gpio,$mode) = @_;
   
   die "Usage : \$pi->set_mode(<gpio>, <mode>)" unless (defined($gpio) && defined($mode));
   
   return $self->send_command(PI_CMD_MODES,$gpio,$mode);
}

=head2 write

Sets the voltage level on a GPIO pin to HI or LOW

Note: You first must set the pin mode to PI_OUTPUT 

Usage :

    $pi->write(17, HI);
or 
    $pi->write(17, LOW);

Arguments:

=over 4

=item * arg1: gpio - GPIO to witch you want to write

=item * arg2: level - The voltage level that you want to write (one of HI or LOW)

=back 

Note: This method will set the GPIO mode to "OUTPUT" and leave it like this

=cut
sub write {
    my ($self,$gpio,$level) = @_;
    
    return $self->send_command(PI_CMD_WRITE,$gpio,$level);
}


=head2 read

Gets the voltage level on a GPIO

Note: You first must set the pin mode to PI_INPUT

Usage :

    $pi->read(17);

Arguments:

=over 4

=item * arg1: gpio - gpio that you want to read

=back

Note: This method will set the GPIO mode to "INPUT" and leave it like this

=cut
sub read {
    my ($self,$gpio) = @_;

    return $self->send_command(PI_CMD_READ,$gpio);
}

=head2 set_watchdog

If no level change has been detected for the GPIO for timeout milliseconds any notification 
for the GPIO has a report written to the fifo with the flags set to indicate a watchdog timeout. 

Arguments: 

=over 4

=item * arg1: gpio - GPIO for which to set the watchdog

=item * arg2. timeout - time to wait for a level change in milliseconds. 

=back

Only one watchdog may be registered per GPIO. 

The watchdog may be cancelled by setting timeout to 0.

NOTE: This method requires another connection to be created and subcribed to 
notifications for this GPIO (see DHT22 implementation)

=cut
sub set_watchdog {
    my ($self,$gpio,$timeout) = @_;
    
    $self->send_command( PI_CMD_WDOG, $gpio, $timeout);
}


=head2 set_pull_up_down

Set or clear the GPIO pull-up/down resistor. 

=over 4

=item * arg1: gpio - GPIO for which we want to modify the pull-up/down resistor

=item * arg2: level - PI_PUD_UP, PI_PUD_DOWN, PI_PUD_OFF.

=back

Usage:

    $pi->set_pull_up_down(18, PI_PUD_DOWN);

=cut
sub set_pull_up_down {
    my ($self,$gpio,$level) = @_;
    
    $self->send_command(PI_CMD_PUD, $gpio, $level);
}


=head2 gpio_trigger

This function sends a trigger pulse to a GPIO. The GPIO is set to level for pulseLen microseconds and then reset to not level. 

Arguments (in this order):

=over 4

=item * arg1: gpio - number of the GPIO pin we want to monitor

=item * arg2: length - pulse length in microseconds

=item * arg3: level - level to use for the trigger (HI or LOW)

=back

Usage:
    
    $pi->gpio_trigger(4,17,LOW);

Note: After running you call this method the GPIO is left in "INPUT" mode

=cut
sub gpio_trigger {
    my ($self,$gpio,$length,$level) = @_;
    
    $self->send_command_ext(PI_CMD_TRIG, $gpio, $length, [ $level ]);
}

=head2 SPI interface

=head3 spi_open

Comunication is done via harware SPI so MAKE SURE YOU ENABLED SPI on your RPi (use raspi-config command and go to "Advanced")

Returns a handle for the SPI device on channel.  Data will be
transferred at baud bits per second.  The flags may be used to
modify the default behaviour of 4-wire operation, mode 0,
active low chip select.

An auxiliary SPI device is available on all models but the
A and B and may be selected by setting the A bit in the
flags. The auxiliary device has 3 chip selects and a
selectable word size in bits.

Arguments:

=over 4

=item * arg1: spi_channel:= 0-1 (0-2 for the auxiliary SPI device).

=item * arg2: baud:= 32K-125M (values above 30M are unlikely to work).

=item * arg3: spi_flags:= see below.

=back

spi_flags consists of the least significant 22 bits.

    21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
    b  b  b  b  b  b  R  T  n  n  n  n   W  A u2 u1 u0 p2 p1 p0  m  m

mm defines the SPI mode.

WARNING: modes 1 and 3 do not appear to work on
the auxiliary device.

    Mode POL PHA
    0    0   0
    1    0   1
    2    1   0
    3    1   1

px is 0 if CEx is active low (default) and 1 for active high.

ux is 0 if the CEx GPIO is reserved for SPI (default)
and 1 otherwise.

A is 0 for the standard SPI device, 1 for the auxiliary SPI.

W is 0 if the device is not 3-wire, 1 if the device is 3-wire.
Standard SPI device only.

nnnn defines the number of bytes (0-15) to write before
switching the MOSI line to MISO to read data.  This field
is ignored if W is not set.  Standard SPI device only.

T is 1 if the least significant bit is transmitted on MOSI
first, the default (0) shifts the most significant bit out
first.  Auxiliary SPI device only.

R is 1 if the least significant bit is received on MISO
first, the default (0) receives the most significant bit
first.  Auxiliary SPI device only.

bbbbbb defines the word size in bits (0-32).  The default (0)
sets 8 bits per word.  Auxiliary SPI device only.

The C<spi_read>, C<spi_write>, and C<spi_xfer> functions
transfer data packed into 1, 2, or 4 bytes according to
the word size in bits.

For bits 1-8 there will be one byte per character. 
For bits 9-16 there will be two bytes per character. 
For bits 17-32 there will be four bytes per character.

E.g. 32 12-bit words will be transferred in 64 bytes.

The other bits in flags should be set to zero.


Example: open SPI device on channel 1 in mode 3 at 50k bits per second

    my $spi_handle = $pi->spi_open(1, 50_000, 3);

=cut
sub spi_open {
    my ($self, $spi_channel, $baud, $spi_flags) = @_;
    
    $spi_flags //= 0;
    
    return $self->send_command_ext(PI_CMD_SPIO, $spi_channel, $baud, [ $spi_flags ]);
}


=head3 spi_close

Closes an SPI channel

Usage :

    my $spi = $pi->spi_open(0,32_000);
    ... 
    $pi->spi_close($spi);

=cut
sub spi_close {
    my ($self, $handle) = @_;
    
    return $self->send_command(PI_CMD_SPIC, $handle, 0);
}
   

=head3 spi_read

Arguments (in this order): 

=over 4

=item * arg1: handle= >=0 (as returned by a prior call to C<spi_open>).

=item * arg2: count= >0, the number of bytes to read.

=back

The returned value is a bytearray containing the bytes.

Usage: 

    my $spi_handle = $pi->spi_open(1, 50_000, 3);

    my $data = $pi->spi_read($spi_handle, 12);

    $pi->spi_close($spi_handle);

=cut
sub spi_read {
    my ($self, $handle, $count) = @_;
    
    $self->send_command(PI_CMD_SPIR, $handle, $count);
    
    my $response;
    
    $self->{sock}->recv($response,3);
    
    return $response;
}


=head3 spi_write

Writes the data bytes to the SPI device associated with handle.

Arguments (in this order):

=over 4

=item * arg1: handle:= >=0 (as returned by a prior call to C<spi_open>).

=item * arg2: data:= the bytes to write.

=back

Examples : 

    my $spi_handle = $pi->spi_open(1, 50_000, 3);

    $pi->spi_write($spi_handle, [2, 192, 128]);      # write 3 bytes to device 1

=cut
sub spi_write {
    my ($self, $handle, $data) = @_;
    
    if (! ref($data) ) {
        $data = [ map {ord} split("",$data) ];
    }
    
    return $self->send_command_ext(PI_CMD_SPIW, $handle, 0, $data);
}

=head3 spi_xfer

Writes the data bytes to the SPI device associated with handle,
returning the data bytes read from the device.

Arguments (in this order):

=over 4

=item * arg1: handle= >=0 (as returned by a prior call to C<spi_open>).

=item * arg2: data= the bytes to write.

=back

The returned value is a bytearray containing the bytes.

Examples :

    my $spi_handle = $pi->spi_open(1, 50_000, 3);

    my $rx_data = $pi->spi_xfer($spi_handle, [1, 128, 0]);

=cut
sub spi_xfer {
    my ($self, $handle, $data) = @_;
    
    if (! ref($data) ) {
        $data = [ map {ord} split("",$data) ];
    }
    
    my $bytes = $self->send_command_ext(PI_CMD_SPIX, $handle, 0, $data);
    
    my $response;
    
    $self->{sock}->recv($response,$bytes);
    
    return $response;
}

=head2 Serial interface

=head3 serial_open

Returns a handle for the serial tty device opened
at baud bits per second.  The device name must start
with /dev/tty or /dev/serial.

Arguments :

=over 4

=item * arg1 : tty => the serial device to open.

=item * arg2 : baud => baud rate in bits per second, see below.

=back

Returns: a handle for the serial connection which will be used
in calls to C<serial_*> methods

The baud rate must be one of 50, 75, 110, 134, 150,
200, 300, 600, 1200, 1800, 2400, 4800, 9600, 19200,
38400, 57600, 115200, or 230400.

Notes: On the raspi on which you want to use the serial device you have to :

=over 4

=item 1 enable UART -> run C<sudo nano /boot/config.txt> and add the bottom C<enable_uart=1>

=item 2 run C<sudo raspi-config> and disable the login via the Serial port

=back

More info (usefull for Raspi 3) here : L<http://spellfoundry.com/2016/05/29/configuring-gpio-serial-port-raspbian-jessie-including-pi-3/>

Usage:

      $h1 = $pi->serial_open("/dev/ttyAMA0", 300)

      $h2 = $pi->serial_open("/dev/ttyUSB1", 19200, 0)

      $h3 = $pi->serial_open("/dev/serial0", 9600)

=cut
sub serial_open {
    my ($self,$tty,$baud) = @_;
    
    my $sock = $self->{sock};

    my $msg = pack('IIII', PI_CMD_SERO, $baud, 0, length($tty));
    
    $sock->send($msg);
    $sock->send($tty);
        
    my $response;
    
    $sock->recv($response,16);
    
    my ($x, $val) = unpack('a[12] I', $response);

    return $val;
}


=head3 serial_close

Closes the serial device associated with handle.

Arguments:

=over 4

=item * arg1: handle => the connection as returned by a prior call to C<serial_open>

=back

Usage:

   $pi->serial_close($handle);

=cut
sub serial_close {
    my ($self,$handle) = @_;
    
    return $self->send_command(PI_CMD_SERC,$handle);
}

=head3 serial_write

Write a string to the serial handle opened with C<serial_open>

Arguments:

=over 4

=item * arg1: handle => connection handle obtained from calling C<serial_open>

=item * arg2: data => data to write (string)

=back

Usage :

    my $h = $pi->serial_open('/dev/ttyAMA0',9600);

    my $data = 'foo bar';

    $pi->serial_write($h, $data);

    $pi->serial_close($h);

=cut
sub serial_write {
    my ($self,$handle,$data) = @_;
    
    my $sock = $self->{sock};
    
    my $msg = pack('IIII', PI_CMD_SERW, $handle, 0, length($data));
    
    $sock->send($msg);
    $sock->send($data);
        
    my $response;
    
    $sock->recv($response,16);
    
    my ($x, $val) = unpack('a[12] I', $response);
}

=head3 serial_read

Read a string from the serial handle opened with C<serial_open>

Arguments:

=over 4

=item * arg1: handle => connection handle obtained from calling C<serial_open>

=item * arg2: count => number of bytes to read

=back

Usage :

    my $h = $pi->serial_open('/dev/ttyAMA0',9600);

    my $data = $pi->serial_read($h, 10); #read 10 bytes

    $pi->serial_close($h);

Note: Between a read and a write you might want to sleep for half a second

=cut
sub serial_read {
    my ($self,$handle,$count) = @_;
    
    my $bytes = $self->send_command(PI_CMD_SERR, $handle, $count);
    
    my $response;
    
    $self->{sock}->recv($response,$count);
    
    return $response;
}

=head3 serial_data_available

Checks if we have any data waiting to be read from the serial handle

Usage :

    my $h = $pi->serial_open('/dev/ttyAMA0',9600);

    my $count = $pi->serial_data_available($h);

    my $data = $pi->serial_read($h, $count);

    $pi->serial_close($h);

=cut
sub serial_data_available {
    my ($self,$handle) = @_;
    
    return $self->send_command(PI_CMD_SERDA, $handle);
}

=head2 I2C interface

=head3 i2c_open

Returns a handle (>=0) for the device at the I2C bus address.

Arguments:

=over 4

=item * i2c_bus: >=0 the i2c bus number

=item * i2c_address: 0-0x7F => the address of the device on the bus

=item * i2c_flags: defaults to 0, no flags are currently defined (optional).  

=back

Physically buses 0 and 1 are available on the Pi.  Higher
numbered buses will be available if a kernel supported bus
multiplexor is being used.

Usage :
    
    my $handle = $pi->i2c_open(1, 0x53) # open device at address 0x53 on bus 1

=cut
sub i2c_open {
    my ($self, $i2c_bus, $i2c_address, $i2c_flags) = @_;
    
    $i2c_flags ||= 0;
    
    return $self->send_command_ext(PI_CMD_I2CO, $i2c_bus, $i2c_address, [$i2c_flags]);
}

=head3 i2c_close

Closes the I2C device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=back

=cut
sub i2c_close {
    my ($self, $handle) = @_;

    return $self->send_command(PI_CMD_I2CC, $handle, 0);
}

=head3 i2c_write_quick

Sends a single bit to the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * bit: 0 or 1, the value to write.

=back

Usage: 

    $pi->i2c_write_quick(0, 1) # send 1 to device 0
    $pi->i2c_write_quick(3, 0) # send 0 to device 3

=cut
sub i2c_write_quick {
    my ($self, $handle, $bit) = @_;
    
    return $self->send_command(PI_CMD_I2CWQ, $handle, $bit);
}

=head3 i2c_write_byte

Sends a single byte to the device associated with handle.

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * byte_val: 0-255, the value to write.

=back

Usage: 

   $pi->i2c_write_byte(1, 17)   # send byte   17 to device 1
   $pi->i2c_write_byte(2, 0x23) # send byte 0x23 to device 2

=cut
sub i2c_write_byte {
    my ($self, $handle, $byte_val) = @_;
    
    return $self->send_command(PI_CMD_I2CWS, $handle, $byte_val);
}

=head3 i2c_read_byte

Reads a single byte from the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=back

Usage:

   my $val = $pi->i2c_read_byte(2) # read a byte from device 2

=cut
sub i2c_read_byte {
    my ($self, $handle) = @_;
    
    return $self->send_command(PI_CMD_I2CRS, $handle, 0);
}

=head3 i2c_write_byte_data

Writes a single byte to the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * byte_val: 0-255, the value to write.

=back

Usage:

   # send byte 0xC5 to reg 2 of device 1
   $pi->i2c_write_byte_data(1, 2, 0xC5);

   # send byte 9 to reg 4 of device 2
   $pi->i2c_write_byte_data(2, 4, 9);

=cut
sub i2c_write_byte_data {
    my ($self, $handle, $reg, $byte_val) = @_;
    
    $self->send_command_ext(PI_CMD_I2CWB, $handle, $reg, [$byte_val]);
}


=head3 i2c_write_word_data

Writes a single 16 bit word to the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * word_val: 0-65535, the value to write.

=back

Usage:

   # send word 0xA0C5 to reg 5 of device 4
   $pi->i2c_write_word_data(4, 5, 0xA0C5);

   # send word 2 to reg 2 of device 5
   $pi->i2c_write_word_data(5, 2, 23);

=cut
sub i2c_write_word_data {
    my ($self, $handle, $reg, $word_val) = @_;
    
    return $self->send_command_ext(PI_CMD_I2CWW, $handle, $reg, [$word_val]);
}

=head3 i2c_read_byte_data

Reads a single byte from the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=back

Usage: 
   # read byte from reg 17 of device 2
   my $b = $pi->i2c_read_byte_data(2, 17);

   # read byte from reg  1 of device 0
   my $b = pi->i2c_read_byte_data(0, 1);

=cut
sub i2c_read_byte_data {
    my ($self, $handle, $reg) = @_;

    return $self->send_command(PI_CMD_I2CRB, $handle, $reg);
}

=head3 i2c_read_word_data

Reads a single 16 bit word from the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=back

Usage: 
   # read byte from reg 17 of device 2
   my $w = $pi->i2c_read_word_data(2, 17);

   # read byte from reg  1 of device 0
   my $w = pi->i2c_read_word_data(0, 1);

=cut
sub i2c_read_word_data {
    my ($self, $handle, $reg) = @_;

    return $self->send_command(PI_CMD_I2CRW, $handle, $reg);
}

=head3 i2c_process_call

Writes 16 bits of data to the specified register of the device associated with handle and reads 16 bits of data in return.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * word_val: 0-65535, the value to write.

=back

Usage:

   my $r = $pi->i2c_process_call(1, 4, 0x1231);
   
   my $r = $pi->i2c_process_call(2, 6, 0);

=cut
sub i2c_process_call {
    my ($self, $handle, $reg, $word_val) = @_;

    return $self->send_command_ext(PI_CMD_I2CPC, $handle, $reg, [$word_val]);
}


=head3 i2c_write_block_data

Writes up to 32 bytes to the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * data: arrayref of bytes to write

=back

Usage:

   $pi->i2c_write_block_data(6, 2, [0, 1, 0x22]);

=cut
sub i2c_write_block_data {
    my ($self, $handle, $reg, $data) = @_;
    
    return 0 unless $data;
    
    croak "data needs to be an arrayref" unless (ref $data eq "ARRAY");
    
    return $self->send_command_ext(PI_CMD_I2CWK, $handle, $reg, $data);
}

=head3 i2c_read_block_data

Reads a block of up to 32 bytes from the specified register of the device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=back

The amount of returned data is set by the device.

The returned value is a tuple of the number of bytes read and a bytearray containing the bytes.  
If there was an error the number of bytes read will be less than zero (and will contain the error code).

Usage:

    my ($bytes,$data) = $pi->i2c_read_block_data($handle, 10);

=cut
sub i2c_read_block_data {
    my ($self, $handle, $reg) = @_;
    
    my ($bytes, $data) = $self->send_i2c_command(PI_CMD_I2CRK, $handle, $reg);
    
    return ($bytes, $data);
}

=head3 i2c_block_process_call

Writes data bytes to the specified register of the device associated with handle and 
reads a device specified number of bytes of data in return.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * data: arrayref of bytes to write

=back

Usage:

   my ($bytes,$data) = $pi->i2c_block_process_call($handle, 10, [2, 5, 16]);
   
The returned value is a tuple of the number of bytes read and a bytearray containing the bytes.

If there was an error the number of bytes read will be less than zero (and will contain the error code).

=cut
sub i2c_block_process_call {
    my ($self, $handle, $reg, $data) = @_;
    
    my ($bytes, $recv_data) = $self->send_i2c_command(PI_CMD_I2CPK, $handle, $reg, [$data]);
    
    return ($bytes, $recv_data);
}

=head3 i2c_write_i2c_block_data

Writes data bytes to the specified register of the device associated with handle.
1-32 bytes may be written.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * data: arrayref of bytes to write

=back

Usage:

   $pi->i2c_write_i2c_block_data(6, 2, [0, 1, 0x22]);

=cut
sub i2c_write_i2c_block_data {
    my ($self, $handle, $reg, $data) = @_;
    
    return $self->send_command_ext(PI_CMD_I2CWI, $handle, $reg, $data);
}

=head3 i2c_read_i2c_block_data

Reads count bytes from the specified register of the device associated with handle.
The count may be 1-32.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * reg: >=0, the device register.

=item * count: >0, the number of bytes to read (1-32).

=back

Usage:

    my ($bytes, $data) = $pi->i2c_read_i2c_block_data($handle, 4, 32);

The returned value is a tuple of the number of bytes read and a bytearray containing the bytes.
If there was an error the number of bytes read will be less than zero (and will contain the error code).

=cut
sub i2c_read_i2c_block_data {
    my ($self, $handle, $reg, $count) = @_;
    
    my ($bytes, $data) = $self->send_i2c_command(PI_CMD_I2CRI, $handle, $reg, [$count]);
    
    return ($bytes, $data);
}

=head3 i2c_read_device

Returns count bytes read from the raw device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * count: >0, the number of bytes to read (1-32).

=back

Usage:

   my ($count, $data) = $pi->i2c_read_device($handle, 12);

=cut
sub i2c_read_device {
    my ($self, $handle, $count) = @_;
    
    my ($bytes, $data) = $self->send_i2c_command(PI_CMD_I2CRD, $handle, $count);

    return ($bytes, $data);
}

=head3 i2c_write_device

Writes the data bytes to the raw device associated with handle.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * data: arrayref of bytes to write

=back

Usage:

   $pi->i2c_write_device($handle, [23, 56, 231]);

=cut
sub i2c_write_device {
    my ($self, $handle, $data) = @_;
    
    return $self->send_command_ext(PI_CMD_I2CWD, $handle, 0, $data);
}


=head3 i2c_zip

This function executes a sequence of I2C operations.
The operations to be performed are specified by the contents of data which contains the concatenated command codes and associated data.

Arguments:

=over 4

=item * handle: >=0 ( as returned by a prior call to C<i2c_open()> )

=item * data: arrayref of the concatenated I2C commands, see below

=back

The returned value is a tuple of the number of bytes read and a bytearray containing the bytes.
If there was an error the number of bytes read will be less than zero (and will contain the error code).

Usage:

   my ($count, $data) = $pi->i2c_zip($handle, [4, 0x53, 7, 1, 0x32, 6, 6, 0])

The following command codes are supported:

   Name    @ Cmd & Data @ Meaning
   End     @ 0          @ No more commands
   Escape  @ 1          @ Next P is two bytes
   On      @ 2          @ Switch combined flag on
   Off     @ 3          @ Switch combined flag off
   Address @ 4 P        @ Set I2C address to P
   Flags   @ 5 lsb msb  @ Set I2C flags to lsb + (msb << 8)
   Read    @ 6 P        @ Read P bytes of data
   Write   @ 7 P ...    @ Write P bytes of data

The address, read, and write commands take a parameter P. Normally P is one byte (0-255).  
If the command is preceded by the Escape command then P is two bytes (0-65535, least significant byte first).

The address defaults to that associated with the handle.
The flags default to 0.  The address and flags maintain their previous value until updated.

Any read I2C data is concatenated in the returned bytearray.

   Set address 0x53, write 0x32, read 6 bytes
   Set address 0x1E, write 0x03, read 6 bytes
   Set address 0x68, write 0x1B, read 8 bytes
   End

   0x04 0x53   0x07 0x01 0x32   0x06 0x06
   0x04 0x1E   0x07 0x01 0x03   0x06 0x06
   0x04 0x68   0x07 0x01 0x1B   0x06 0x08
   0x00

=cut
sub i2c_zip {
    my ($self, $handle, $commands) = @_;
    
    my ($bytes, $data) = $self->send_i2c_command(PI_CMD_I2CZ, $handle, 0, $commands);
    
    return ($bytes, $data);
}


=head2 PWM

=head3 write_pwm

Sets the voltage level on a GPIO pin to a value from 0-255 (PWM) 
approximating a lower voltage.  Useful for dimming LEDs for example.

Note: You first must set the pin mode to PI_OUTPUT

Usage :

    $pi->write_pwm(17, 255);
or
    $pi->write_pwm(17, 120);
or
    $pi->write_pwm(17, 0);

Arguments:

=over 4

=item * arg1: gpio - GPIO to which you want to write

=item * arg2: level - The voltage level that you want to write (one of 0-255)

=back

Note: This method will set the GPIO mode to "OUTPUT" and leave it like this

=cut
sub write_pwm {
    my ($self,$gpio,$level) = @_;

    return $self->send_command(PI_CMD_PWM,$gpio,$level);
}

################################################################################################################################

=head1 PRIVATE METHODS

=cut

=head2 send_command

Sends a command to the pigiod daemon and waits for a response

=over 4

=item * arg1: command - code of the command you want to send (see package constants)

=item * arg2: param1 - first parameter (usualy the GPIO)

=item * arg3: param2 - second parameter - optional - usualy the level to which to set the GPIO (HI/LOW)

=back

=cut
sub send_command {
    my $self = shift;
    
    if (! $self->{sock}->connected) {
        $self->{sock} = IO::Socket::INET->new(
                            PeerAddr => $self->{address},
                            PeerPort => $self->{port},
                            Proto    => 'tcp'
                            );
    }
    
    return unless $self->{sock};
    
    return $self->send_command_on_socket($self->{sock},@_);
}

=head2 send_command_on_socket

Same as C<send_command> but allows you to specify the socket you want to use

The pourpose of this is to allow you to use the send_command functionality on secondary 
connections used to monitor changes on GPIO

Arguments:

=over 4

=item * arg1: socket - Instance of L<IO::Socket::INET>

=item * arg2: command - code of the command you want to send (see package constants)

=item * arg3: param1 - first parameter (usualy the GPIO)

=item * arg3: param2 - second parameter - optional - usualy the level to which to set the GPIO (HI/LOW)

=back

=cut
sub send_command_on_socket {
    my ($self, $sock, $cmd, $param1, $param2) = @_;
    
    $param2 //= 0;
    
    my $msg = pack('IIII', $cmd, $param1, $param2, 0);
    
    $sock->send($msg);
    
    my $response;
    
    $sock->recv($response,16);
    
    my ($x, $val) = unpack('a[12] I', $response);

    return $val;
}


=head2 send_command_ext

Sends an I<extended command> to the pigpiod daemon

=cut
sub send_command_ext {
    my ($self,$cmd,$param1,$param2,$extra_params) = @_;
    
    my $sock; 
    if (ref($self) ne "IO::Socket::INET") {
        $sock = $self->{sock};
    }
    else {
        $sock = $self;
    }
     
    my $msg = pack('IIII', $cmd, $param1, $param2, 4 * scalar(@{$extra_params // []}));
    
    $sock->send($msg);
    
    foreach (@{$extra_params // []}) {
       $sock->send(pack("I",$_));
    }
    
    my $response;
    
    $sock->recv($response,16);
    
    my ($x, $val) = unpack('a[12] I', $response);

    return $val;
}

=head2 send_i2c_command 

Method used for sending and reading back i2c data

=cut
sub send_i2c_command {
    my ($self, $command, $handle, $reg, $data) = @_;
    
    $data //= [];
    
    my $bytes = $self->send_command_ext($command, $handle, $reg, $data);

    if ($bytes > 0) {
        my $response;
        $self->{sock}->recv($response,$bytes);
        return $bytes, [unpack("C"x$bytes, $response)];
    }
    else {
        return $bytes, "";
    }
}

sub prepare_for_exit {
    my $self = shift;
    
    $self->{sock}->close() if $self->{sock};
}

sub DESTROY {
    my $self = shift;
    
    $self->prepare_for_exit();
}

1;
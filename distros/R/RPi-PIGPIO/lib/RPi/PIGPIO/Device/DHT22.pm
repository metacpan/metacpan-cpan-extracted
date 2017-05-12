package RPi::PIGPIO::Device::DHT22;

=head1 NAME

RPi::PIGPIO::Device::DHT22 - Read temperature and humidity from a DHT22 sensor

=head1 DESCRIPTION

Uses the pigpiod to read temperature and humidity from a local or remote DHT22 sensor

=head1 SYNOPSIS

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::DHT22;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $dht22 = RPi::PIGPIO::Device::DHT22->new($pi,4);

    $dht22->trigger(); #trigger a read

    print "Temperature : ".$dht22->temperature."\n";
    print "Humidity : ".$dht22->humidity."\n";

=cut

use strict;
use warnings;

use Carp;
use RPi::PIGPIO ':all';

use Time::HiRes qw/usleep/;

=head1 METHODS

=head2 new

Create a new object

Usage:

    my $dht22 = RPi::PIGPIO::Device::DHT22->new($pi,$gpio);

Arguments: 

=over 4

=item * $pi - an instance of RPi::PIGPIO

=item * $gpio - GPIO number to which the sensor is connected

=back

=cut
sub new {
    my ($class,$pi,$gpio) = @_;
    
    if (! $gpio) {
        croak "new() expects the second argument to be the GPIO number on which the DTH22 sensor data pin is connected!";
    }
    
    if (! $pi || ! ref($pi) || ref($pi) ne "RPi::PIGPIO") {
        croak "new expectes the first argument to be a RPi::PIPGIO object!";
    }
    
    my $self = {
        pi => $pi,
        gpio => $gpio,
        temperature => undef,
        humidity => undef,
        last_read => undef,
        high_tick => 0,
        invalid_reads => 0,
    };
    
    bless $self, $class;
    
    $self->reset_readings();
        
    return $self;
}

=head2 temperature

Return the last read temperature

=cut
sub temperature { 
    my $self = shift;
    
    return $self->{temperature};
}

=head2 humidity

Return the last read humidity

=cut
sub humidity {
    my $self = shift;
    
    return $self->{humidity};
}

=head2 last_read

When was the last read done (unix timestamp)

=cut
sub last_read {
    my $self = shift;
    
    return $self->{last_read};
}

=head2 trigger

Trigger a new read from the sensor.

Note: The read is not imediate, it's done asyncronyous. After calling trigger 
you shoud sleep for a second and than you should get the values received by calling 
temperature() and humidity() .

You should always chek the timestamp of the last read to make sure we were actually 
able to read the data after you called trigger()

DHT22 can freeze if you call trigger too often. Don't call it more than every 3 seconds 
and you should be fine

=cut
sub trigger {
    my $self = shift;
    
    $self->reset_readings();
    
    my $sock = IO::Socket::INET->new(
                        PeerAddr => $self->{pi}{host},
                        PeerPort => $self->{pi}{port},
                        Proto    => 'tcp'
                        );
    
    die "DHT22 failed to connect to $self->{pi}{host}:$self->{pi}{port}!" unless $sock;
    
    my $handle = $self->{pi}->send_command_on_socket($sock, PI_CMD_NOIB, 0, 0);
    
    my $lastLevel = $self->{pi}->send_command(PI_CMD_BR1, 0, 0);
    
    #Subscribe to level changes on the DHT22 GPIO
    $self->{pi}->send_command(PI_CMD_NB, $handle , 1 << $self->{gpio});
    
    #$self->{pi}->gpio_trigger($self->{gpio}, 20, LOW);
    
    $self->{pi}->set_mode($self->{gpio},PI_OUTPUT);
    $self->{pi}->write($self->{gpio},LOW);
    usleep(17);
    $self->{pi}->set_mode($self->{gpio},PI_INPUT);
     
    $self->{pi}->set_watchdog($self->{gpio}, 200);
    
    $self->reset_readings();
        
    my $MSG_SIZE = 12;
    
    my $timeouts = 0;
        
    while ($self->{bit} < 40 && $timeouts < 5) {
            
        my $buffer;
                    
        my $read_buf;
        
        $sock->recv($buffer, $MSG_SIZE);
        
        if ($self->{bit} == 0) {
            $self->{pi}->set_watchdog($self->{gpio}, 0);
        }
        
        while ( length($buffer) < $MSG_SIZE ) {
           $sock->recv($read_buf, $MSG_SIZE-length($buffer));
           $buffer .= $read_buf;
        }
        
        my ($seq, $flags, $tick, $level) = unpack('SSII', $buffer);
        
        #warn "Received : $seq | $flags | $tick | $level ";
        
        if ($flags && NTFY_FLAGS_WDOG) {
            warn "DHT22: Timeout in GPIO : ".($flags & NTFY_FLAGS_GPIO);
            $timeouts++;
        }
        else {
            my $changed = $level ^ $lastLevel;
            $lastLevel = $level;
            
            if ( (1<<$self->{gpio}) & $changed ) {
                my $newLevel = 0;
                
                if ( (1<<$self->{gpio}) & $level ) {
                    $newLevel = 1;
                }
                     
                if (EITHER_EDGE ^ $newLevel) {
                    $self->receive_data($newLevel,$tick);
                }    
            }
            
        }
    }
    
    $self->{pi}->send_command_on_socket($sock, PI_CMD_NC, $handle, 0);
    
    $sock->close;
        
}

=head1 PRIVATE METHODS

=head2 receive_data

Callback method used to read and put together the data received from the sensor

=cut
sub receive_data {
    my ($self, $level, $tick ) = @_;
    
    #  Accumulate the 40 data bits.  Format into 5 bytes, humidity high,
    #  humidity low, temperature high, temperature low, checksum.

    my $diff = tick_diff( $self->{high_tick}, $tick );

    my $val;

    if ( $level == 0 ) {
        
        # Edge length determines if bit is 1 or 0.
        if ( $diff >= 50 ) {
            $val = 1;
            if ( $diff >= 200 ) {    # Bad bit?
                $self->{cksum} = 256    # Force bad checksum.
            }
        }
        else {
            $val = 0;
        }
        

        if ( $self->{bit} >= 40 ) {     # Message complete.
            $self->{bit} = 40;
        }
        elsif ( $self->{bit} >= 32 ) {    # In checksum byte.
            $self->{cksum} = ( $self->{cksum} << 1 ) + $val;            
        }
        elsif ( $self->{bit} >= 24 ) {    # in temp low byte
            $self->{t_lo} = ( $self->{t_lo} << 1 ) + $val;
        }
        elsif ( $self->{bit} >= 16 ) {    # in temp high byte
            $self->{t_hi} = ( $self->{t_hi} << 1 ) + $val;
        }
        elsif ( $self->{bit} >= 8 ) {     # in humidity low byte
            $self->{h_lo} = ( $self->{h_lo} << 1 ) + $val;
        }
        elsif ( $self->{bit} >= 0 ) {     # in humidity high byte
            $self->{h_hi} = ( $self->{h_hi} << 1 ) + $val;
        }
        else {                            # header bits

        }
        
        $self->{bit}++;
        
        if ( $self->{bit} == 40 ) {
            
            my $total = $self->{h_hi} + $self->{h_lo} + $self->{t_hi} + $self->{t_lo};

            if ( ( $total & 255 ) == $self->{cksum} ) {    # Is checksum ok?
        
                $self->{humidity} = ( ( $self->{h_hi} << 8 ) + $self->{h_lo} ) * 0.1;
            
                my $multiplier = 0.1;

                if ( $self->{t_hi} & 128 ) {    # Negative temperature.
                    $multiplier = -0.1;
                    $self->{t_hi} = $self->{t_hi} & 127;
                }

                $self->{temperature} = ( ( $self->{t_hi} << 8 ) + $self->{t_lo} ) * $multiplier;
            
                $self->{last_read} = time();
            }
            else {
                $self->{invalid_reads}++;
                warn "DHT22: Invalid read !";
            }
        }
        

    }
    elsif ( $level == 1 ) {
        
        $self->{high_tick} = $tick;

        if ( $diff > 250000 ) {
            $self->reset_readings;
        }
    }
    
    return 1;
}

=head2 reset_readings

Reset internal counters that help us put together data received from the sensor

=cut
sub reset_readings {
    my $self = shift;
    
    $self->{bit}   = -2;
    $self->{h_hi}  = 0;
    $self->{h_lo}  = 0;
    $self->{t_hi}  = 0;
    $self->{t_lo}  = 0;
    $self->{cksum} = 0;
    #$self->{high_tick} = 0;
}


sub tick_diff {
    my ($t1,$t2) = @_;
    
    my $diff = $t2 - $t1;
    
    if ($diff < 0) {
      $diff += (1 << 32)
    }
    
    return $diff;
}

sub DESTROY {
    my $self = shift;
}

1;
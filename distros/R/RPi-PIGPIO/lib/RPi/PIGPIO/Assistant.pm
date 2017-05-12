package RPi::PIGPIO::Assistant;

=head1 NAME

RPi::PIGPIO::Assistant - Methods for reverse engeniering devices

=head1 DESCRIPTION

This module is a helper that can be used to easely debug things on a GPIO

=head1 SYNOPSIS

You can use this one-liner to monitor level changes on a gpio

    perl -Ilib  -MRPi::PIGPIO::Assistant -e "RPi::PIGPIO::Assistant->new('192.168.1.23')->intercept(gpio => 18);"
    
Note: This example assumes that pigpiod is running on the Raspberry Pi with the IP address 192.168.1.23

=cut

use strict;
use warnings;

use RPi::PIGPIO ':all';

=head1 METHODS

=head2 new

Creates a new RPi::PIGPIO::Assistant object 

Params:

=over 4

=item 1. ip address of the Raspi running the pigpiod daemon

=item 2. port on which pigpiod is listening (defaults to 8888)

=back

or 

=over 4

=item 1. an instance of a C<RPi::PIGPIO>

=back

=cut

sub new {
    my ($class, $param1, $param2) = @_;
    
    my $self = {};
    
    if (ref($param1) eq "RPi::PIGPIO") {
        $self->{pi} = $param1;
    }
    else {
        $self->{pi} = RPi::PIGPIO->connect($param1, $param2);
    }
    
    bless $self, $class;
}

=head2 intercept

Monitors a given GPIO for level changes

Params:

=over 4 

=item gpio => GPIO which you want to monitor (mandatory)

=item pud => Pull-up/down level to set for the given gpio, (optional) one of

=over 8

=item 0 => OFF

=item 1 => DOWN

=item 2 => UP

=back 

=back 

Usage:

    $assistant->intercept(gpio => 18, pud => 0);

=cut
sub intercept {
    my ($self, %params) = @_;
    
    local $|=1;
    
    my $sock = IO::Socket::INET->new(
                        PeerAddr => $self->{pi}{host},
                        PeerPort => $self->{pi}{port},
                        Proto    => 'tcp'
                        );
    
    my $gpio = $params{gpio};
    
    die "Assistant failed to connect to $self->{pi}{host}:$self->{pi}{port}!" unless $sock;
    
    my $handle = $self->{pi}->send_command_on_socket($sock, PI_CMD_NOIB, 0, 0);
    
    my $lastLevel = $self->{pi}->send_command(PI_CMD_BR1, 0, 0);
    
    #Subscribe to level changes on the DHT22 GPIO
    $self->{pi}->send_command(PI_CMD_NB, $handle , 1 << $gpio);
    
    $self->{pi}->set_mode($gpio,PI_INPUT);
    
    if (defined $params{pud}) {
        $self->{pi}->set_pull_up_down($gpio, $params{pud});
    }
    
    my $MSG_SIZE = 12;
    
    while (1) {
        my $buffer;
                    
        my $read_buf;
        
        $sock->recv($buffer, $MSG_SIZE);
                
        while ( length($buffer) < $MSG_SIZE ) {
           $sock->recv($read_buf, $MSG_SIZE-length($buffer));
           $buffer .= $read_buf;
        }
        
        my ($seq, $flags, $tick, $level) = unpack('SSII', $buffer);
        
        if ($flags && NTFY_FLAGS_WDOG) {
            print "Watchdog signal received: timeout in GPIO : ".($flags & NTFY_FLAGS_GPIO)."\n";
        }
        else {
            my $changed = $level ^ $lastLevel;
            $lastLevel = $level;
            
            if ( (1<<$gpio) & $changed ) {
                my $newLevel = 0;
                
                if ( (1<<$gpio) & $level ) {
                    $newLevel = 1;
                }

                print "Received : seq => $seq | flags => $flags | tick => $tick | level => $newLevel \n";
            }
        }
    }

}

1;
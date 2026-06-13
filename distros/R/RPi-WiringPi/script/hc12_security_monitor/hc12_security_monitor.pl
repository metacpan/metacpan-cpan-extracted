#!/usr/bin/env perl

use warnings;
use strict;

use Net::SMTP;
use RPi::WiringPi;

use constant {
    DEBUG       => 1,
    DEBUG_SMTP  => 0,

    SEND_TEXT   => 0,

    BIT_BSMT_PIR        => 0,
    BSMT_PIR_OFF        => 50,
    BSMT_PIR_ON         => 51,

    BIT_BSMT_DOOR       => 1,
    BSMT_DOOR_CLOSED    => 60,
    BSMT_DOOR_OPEN      => 61,

    BIT_MAIN_PIR        => 2,

    BIT_ALARM           => 7,
};

# ---

my $sec_byte = 0;

my ($bsmt_pir_state, $bsmt_door_state, $main_state, $alarm_state) = (0, 0, 0, 0);

my $security_devices = {
    5   => { code => \&bsmt_pir, name => 'BSMT PIR' },
};

my $pi = RPi::WiringPi->new(
    label        => 'hc12_security_monitor.pl',
    rpi_register => 0
);

my $s = $pi->serial('/dev/ttyUSB0', 9600);

my $data;
my $start_char = '[';
my $end_char = ']';

my ($rx_started, $rx_ended) = (0, 0);

my $wait_time = 0;
my $prev_time = time;

while (1){

#    if (time - $wait_time > $prev_time) {
        if ($s->avail) {
            my $data_populated = rx($start_char, $end_char);

            if ($data_populated) {
                # print $data;
                execute_command($data);
                rx_reset();
            }
        }
        $prev_time = time;
#    }
    select(undef, undef, undef, 0.1);
}

sub sec_byte {
    my ($bit, $state) = @_;
    $sec_byte ^= (-$state ^ $sec_byte) & (1 << $bit);
    return $sec_byte;
}
sub execute_command {
    my ($command) = @_;

    my ($dev, $state) = split //, $command;

    print "$security_devices->{$dev}{name}: STATE: $state\n" if DEBUG;
    $security_devices->{$dev}{code}($state);
}

sub bsmt_pir {
    my ($state) = @_;

    if ($state){
        print "Motion detected on the PIR!\n" if ! $bsmt_pir_state;

        if (! $bsmt_pir_state){
            text("PIR motion detected!");
        }
        $bsmt_pir_state = 1;
    }
    else {
        print "...motion stopped\n" if $bsmt_pir_state;
        $bsmt_pir_state = 0;
    }

    sec_byte(BIT_BSMT_PIR, $state);
}

sub rx {
    my ($start, $end) = @_;

    my $c = chr $s->getc; # getc() returns the ord() val on a char* perl-wise

    print ">$c<\n";

    if ($c ne $start && ! $rx_started){
        rx_reset();
        return;
    }

    if ($c eq $start){
        $rx_started = 1;
        return;
    }

    if ($c eq $end){
        $rx_ended = 1;
    }

    if ($rx_started && ! $rx_ended){
        $data .= $c;
    }

    if ($rx_started && $rx_ended){
        return local_crc($data)  == remote_crc($data) ? 1 : 0;
    }
}
sub local_crc {
    return $s->crc($_[0], length $_[0]);
}
sub remote_crc {

    while ($s->avail < 2){} # loop until we have two bytes to make up the CRC

    my $msb = $s->getc;
    my $lsb = $s->getc;
    my $crc = ($msb << 8) | $lsb;

    return if $msb == -1 || $lsb == -1;
    return $crc;
}
sub rx_reset {
    $rx_started = 0;
    $rx_ended = 0;
    $data = '';
}
sub text {
    my ($message) = @_;

    return if ! SEND_TEXT;

    if (! $ENV{GMAIL_PW}){
        warn "You need to set your GMail password in the GMAIL_PW env var!\n";
        return;
    }
    if (! $ENV{GMAIL_ADDR}){
        warn "You need to set your GMail address in the GMAIL_ADDR env var!\n";
        return;
    }
    if (! $ENV{GMAIL_TO}){
        warn "You need to set your GMail recipient in the GMAIL_TO env var!\n";
        return;
    }
    if (! $ENV{GMAIL_SERVER}){
        warn "You need to set your GMail server in the GMAIL_SERVER env var!\n";
        return;
    }

    my $smtp = Net::SMTP->new(
        $ENV{GMAIL_SERVER},
        Hello => 'local.example.com',
        Timeout => 30,
        Debug   => DEBUG_SMTP,
        SSL     => 1,
    );

    $smtp->auth($ENV{GMAIL_ADDR}, $ENV{GMAIL_PW})
        or die $!;
    $smtp->mail($ENV{GMAIL_ADDR});
    $smtp->to($ENV{GMAIL_TO});
    $smtp->data();
    $smtp->datasend($message);
    $smtp->quit();
}

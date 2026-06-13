#!/usr/bin/env perl

use warnings;
use strict;

use 5.10.0;

use File::Touch;
use DateTime;
use RPi::WiringPi;

my $oled_lock = '/dev/shm/oled_in_use';
touch $oled_lock;

$SIG{INT} = sub { unlink $oled_lock or die $!; };

# use kill -15 procid && kill -9 procid to terminate the app

$SIG{TERM} = sub { print "$0: Terminated\n"; unlink $oled_lock or die $!; };

my $pi = RPi::WiringPi->new(
    label => 'oled display date/time',
    rpi_register => 0,
    shm_key => 'rpit'
);

my $oled = RPi::WiringPi->oled('128x64', 0x3C, 0);
my $bmp = $pi->bmp(400);

$oled->text_size(2);

while (1){

    if (-e '/dev/shm/oled_unavailable.rpi-wiringpi'){
        sleep 30;
        next;
    }

    $oled->clear;

    my $dt = DateTime->now(time_zone => 'local');
    my $Tc = sprintf('%.02f', $bmp->temp('c'));
    my $Tf = sprintf('%.02f', $bmp->temp);
    my $p = $bmp->pressure * 10;

    $oled->string(str_format($dt->ymd));

    my $min = $dt->minute;
    if (length($min) == 1){
        $min = "0$min";
    }

    $oled->string(str_format($dt->hour . ":" . $min));

    $oled->string(str_format($Tc . " C"));
    $oled->string(str_format($p . " hPa", 1));

    $oled->display;

    sleep 30;
}

sub str_format {
    my $str = shift;

    my $str_len = length $str;

    return $str if $str_len == 10;

    my $to_add = 10 - $str_len;

    $str .= " " x $to_add;

    return $str;
}

END {
    unlink $oled_lock or die $!;
}

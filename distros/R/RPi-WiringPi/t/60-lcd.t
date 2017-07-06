use warnings;
use strict;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);
use Test::More;

$SIG{__DIE__} = sub {
    like shift, qr/Maximum number of LCD/, "initializing too many LCDs error ok";
};

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    plan skip_all => "not on a pi board\n";
}

if (! $ENV{PI_LCD_TEST}){
    warn "\n*** PI_LCD_TEST is not set***\n";
    plan skip_all => "skipping LCD tests\n";
}

my $continue = 1;
$SIG{INT} = sub { $continue = 0; };

my $pi = RPi::WiringPi->new;

my %args = (
    cols => 16,
    rows => 2,
    bits => 4,
    rs => 5,
    strb => 6,
    d0 => 4,
    d1 => 17,
    d2 => 27,
    d3 => 22,
    d4 => 0,
    d5 => 0, 
    d6 => 0, 
    d7 => 0,
);

my $lcd = $pi->lcd(%args);

$lcd->position(0, 0);
$lcd->print("hello, world!"); 

$lcd->position(0, 1);
$lcd->print("line two!");

sleep 2;

$lcd->clear;

is 1, 1, "ok";


my $ok = eval {
    while (1){
        $lcd->init(%args);
        $lcd->position(0, 0);
    }
    1;
};

is $ok, undef, "initializing too many LCD objects dies ok";

$pi->cleanup;

check_pin_status();

done_testing();

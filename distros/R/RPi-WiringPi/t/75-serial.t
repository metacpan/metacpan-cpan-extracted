use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

my $mod = 'RPi::WiringPi';


if ($> == 0){
    $ENV{PI_BOARD} = 1;
    $ENV{RPI_SERIAL} = 1;
}

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
    exit;
}

if (! $ENV{RPI_SERIAL}){
    plan skip_all => "RPI_SERIAL not set; Not running RPI::Serial tests\n";
    exit;
}

if ($> != 0){
    print "enforcing sudo for Serial tests...\n";
    system('sudo', 'perl', $0);
    exit;
}

my $pi = $mod->new;

my $s = $pi->serial("/dev/ttyAMA0", 115200);

isa_ok $s, 'RPi::Serial';

$s->putc(254);
is $s->getc, 254, "putc() and getc() ok";

$s->puts("hello, world!");
is $s->gets(13), "hello, world!", "puts() and gets() ok";

$pi->cleanup;

check_pin_status();

done_testing();

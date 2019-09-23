use warnings;
use strict;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

if (! $ENV{RPI_SHIFTREG}){
    plan skip_all => "RPI_SHIFTREG environment variable not set\n";
}

if (! $ENV{RPI_MCP3008}){
    plan skip_all => "RPI_MCP3008 environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

my $adc_pin = 26;

my $pi = RPi::WiringPi->new;

my $adc = $pi->adc(
    model => 'MCP3008',
    channel => $adc_pin
);

my $sr = $pi->shift_register(400, 8, 21, 20, 16);

my $sr_pin;

$sr_pin = $pi->pin(401);

$sr_pin->write(LOW);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) < 2, "SR pin 1 low ok";


$sr_pin->write(HIGH);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) > 90, "SR pin 1 HIGH ok";

$sr_pin->write(LOW);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) < 2, "SR pin 1 low ok";

$sr_pin->write(LOW);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) < 2, "SR pin 1 low ok";

$sr_pin->write(HIGH);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) > 90, "SR pin 1 HIGH ok";

$sr_pin->write(LOW);
#print $adc->percent(2) . "\n\n";
ok $adc->percent(2) < 2, "SR pin 1 low ok";

$pi->cleanup;

select(undef, undef, undef, 0.2);
check_pin_status();

done_testing();

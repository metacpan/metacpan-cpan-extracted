use warnings;
use strict;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

if (! $ENV{RPI_SHIFTREG}){
    plan skip_all => "RPI_SHIFTREG environment variable not set\n";
}

if (! $ENV{RPI_MCP3008}){
    plan skip_all => "RPI_MCP3008 environment variable not set\n";
}

rpi_running_test(__FILE__);

my $adc_pin = 26;

my $pi = RPi::WiringPi->new(label => 't/335-shift_reg_adc.t', shm_key => 'rpit');
# Belt-and-braces: if an assertion or library call dies mid-run, release the
# pins/registration this object holds (the library END reap is best-effort)

END { $pi->cleanup if $pi && ! $pi->{clean}; }


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

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

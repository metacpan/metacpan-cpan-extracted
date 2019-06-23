use warnings;
use strict;

use constant PWM_MAX => 1023;

use RPi::Const qw(:all);
use RPi::WiringPi;

die if $> != 0;

my $pi = RPi::WiringPi->new;
my $arduino = $pi->i2c(0x04);


my $adc = $pi->adc(
    model => 'MCP3008',
    channel => 26
);

my $ads = $pi->adc;

my $led_pin = $pi->pin(18);
$led_pin->mode(PWM_OUT);
$pi->pwm_mode(PWM_MODE_BAL);
$pi->pwm_clock(32);
$pi->pwm_range(1023);


for (0..PWM_MAX){
    next if $_ % 100 != 1;

    $led_pin->pwm($_);
    my $x = $ads->percent(0);
    print "ads: $x\n";    
#    print "pin " . $led_pin->num ." at pwm $_ is at $input % output capacity\n";
    #for (0..7){
        #     print "$_: " . $adc->percent($_) . "\n";
        #}
    select(undef, undef, undef, 0.3);
}

print "\n\n";

#$led_pin->pwm(512);

for (1..10){
#    my $input = $adc->percent(4);
#    my $x = $ads->percent(0);
#    print "ads: $x\n";    

#    print "pin ". $led_pin->num ." at pwm 512 is at $input % output capacity\n";
#    $led_pin->pwm($_);
#    my @a = $arduino->read_block(2, 80);
#    my $num = ($a[0] << 8) | $a[1];
#    print "$num\n"; 

#    for (0..7){
#        print "$_: " . $adc->percent($_) . "\n";
#    }
#    select(undef, undef, undef, 0.3);
}

$pi->cleanup;

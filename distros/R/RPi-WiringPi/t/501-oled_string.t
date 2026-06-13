use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/501-oled_string.t', shm_key => 'rpit');

my $s = $pi->oled('128x64', 0x3C, 0);

for (1..5) {
    $s->clear;
    my $size_r = $s->text_size($_);
    is $size_r, 1, "return from text_size($_) ok";
    my $string_r = $s->string("hello", 1);
    is $string_r, 1, "return from string() ok";

}
$s->clear;
$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();


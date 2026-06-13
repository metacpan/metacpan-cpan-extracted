use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use JSON;
use RPi::WiringPi;
use RPi::Const qw(:all);
use WiringPi::API qw(:perl);

my $pi = RPi::WiringPi->new;

my $pin_num = 2;

my $j = $ENV{RPI_PINS};

my $p = $j ? decode_json $j : {};

if (exists $p->{$pin_num}){
    die "pin in use...\n";
}

$p->{$pin_num}{alt} = $pi->get_alt($pin_num);
$p->{$pin_num}{state} = $pi->read_pin($pin_num);

print Dumper $p;

$j = encode_json $p;

say $j;

$ENV{RPI_PINS} = $j;




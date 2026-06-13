use strict;
use warnings;
use 5.010;

use Data::Dumper;
use File::Touch qw(touch);
use RPi::WiringPi;

my $f = 'ready.multi';

my $pi = RPi::WiringPi->new(label => 'full_slave.pl', shm_key => 'rpit');

my $p18 = $pi->pin(18, "eighteen");
my $p26 = $pi->pin(26, "twenty-six");

touch $f or die $!;
mywait();

my $p21 = $pi->pin(21, "twenty-one");
my $p16 = $pi->pin(16, "sixteen");

touch $f or die $!;
mywait();

$pi->cleanup;

sub mywait {
    while (1){
        last if ! -e $f;
        select(undef, undef, undef, 0.2);
    }
}

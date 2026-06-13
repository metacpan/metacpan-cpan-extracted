use strict;
use warnings;
use 5.010;

use Data::Dumper;
use File::Touch qw(touch);
use RPi::WiringPi;

print "SLAVE PROC: $$\n";
my $f = 'ready.multi';

my $pi = RPi::WiringPi->new(label => 'multi_die_slave', shm_key => 'rpit');

my $p18 = $pi->pin(18, "112-die_slave");

touch $f or die $!;
mywait();

die();

#$pi->cleanup;

sub mywait {
    while (1){
        last if ! -e $f;
        select(undef, undef, undef, 0.2);
    }
}



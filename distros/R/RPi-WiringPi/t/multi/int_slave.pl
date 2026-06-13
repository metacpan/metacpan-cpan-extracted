use strict;
use warnings;
use 5.010;

use Data::Dumper;
use File::Touch qw(touch);
use RPi::WiringPi;

my $f = 'ready.multi';

my $pi = RPi::WiringPi->new(label => 'multi_int_slave', shm_key => 'rpit');

my $p18 = $pi->pin(18, "114-int_slave");

touch $f or die $!;
mywait();

kill 'INT', $$;

print "\n*** SHOULDN'T BE HERE\n\n";

#$pi->cleanup;

sub mywait {
    while (1){
        last if ! -e $f;
        select(undef, undef, undef, 0.2);
    }
}



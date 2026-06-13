use strict;
use warnings;
use 5.010;

use lib 't/';

use RPiTest;
use Data::Dumper;
use RPi::WiringPi;
use Test::More;

rpi_running_test('t/112-multi-full.t');

my $f = 'ready.multi';

my $pi = RPi::WiringPi->new(label => 'multi-full', shm_key => 'rpit');
my $meta;
my $obj_count = rpi_legal_object_count(); # in use, existing objects

print "\n*** Two pins remote, single pin local ***\n\n";

$meta = $pi->meta_fetch;

is exists($meta->{objects}{$pi->uuid}), 1, "$$ set in meta ok";
is $meta->{objects}{$pi->uuid}{proc}, $$, "UUID proc set to procID $$ in meta ok";
is keys %{ $meta->{objects} }, 2 + $obj_count, "both procs have registered in meta";

$pi->pin(12);

$meta = $pi->meta_fetch;

is exists($meta->{pins}{12}), 1, "pin 12 exists for master proc ok";
is $meta->{pins}{12}{users}{$pi->uuid}, 1, "pin 12 has local UUID as user ok";
is exists($meta->{pins}{18}), 1, "pin 18 exists for slave ok";
is $meta->{pins}{18}{users}{$pi->uuid}, undef, "pin 18 doesn't have local UUID as user ok";
is exists($meta->{pins}{26}), 1, "pin 26 exists for slave ok";
is $meta->{pins}{26}{users}{$pi->uuid}, undef, "pin 26 doesn't have local UUID as user ok";

is keys %{ $meta->{pins} }, 3, "three pins registered so far ok";

mywait();
unlink $f or die $!;

mywait();
unlink $f or die $!;

print "\n*** External script: Second two pins ***\n\n";

$meta = $pi->meta_fetch;

is exists($meta->{pins}{12}), 1, "pin 12 exists for master proc ok";
is $meta->{pins}{12}{users}{$pi->uuid}, 1, "pin 12 has local UUID as user ok";
is exists($meta->{pins}{18}), 1, "pin 18 exists for slave ok";
is $meta->{pins}{18}{users}{$pi->uuid}, undef, "pin 18 doesn't have local UUID as user ok";
is exists($meta->{pins}{26}), 1, "pin 26 exists for slave ok";
is $meta->{pins}{26}{users}{$pi->uuid}, undef, "pin 26 doesn't have local UUID as user ok";
is exists($meta->{pins}{21}), 1, "pin 21 exists for slave ok";
is $meta->{pins}{21}{users}{$pi->uuid}, undef, "pin 21 doesn't have local UUID as user ok";
is exists($meta->{pins}{16}), 1, "pin 16 exists for slave ok";
is $meta->{pins}{16}{users}{$pi->uuid}, undef, "pin 16 doesn't have local UUID as user ok";

is keys %{ $meta->{pins} }, 5, "now have five pins registered";

sleep 2;

print "\n*** External script: Cleaned up ***\n\n";

$meta = $pi->meta_fetch;

is exists($meta->{objects}{$pi->uuid}), 1, "$$ set in meta ok";
is $meta->{objects}{$pi->uuid}{proc}, $$, "UUID set to procID $$ in meta ok";
is keys %{ $meta->{objects} }, 1 + $obj_count, "the remote proc UUID is now removed from shared mem";

is exists($meta->{pins}{12}), 1, "pin 12 exists for master proc ok";
is $meta->{pins}{12}{users}{$pi->uuid}, 1, "pin 12 has local UUID as user ok";
is exists($meta->{pins}{18}), '', "pin 18 is gone";
is exists($meta->{pins}{26}), '', "pin 26 is gone";
is exists($meta->{pins}{21}), '', "pin 21 is gone";
is exists($meta->{pins}{16}), '', "pin 16 is gone";

is keys %{ $meta->{pins} }, 1, "back to only one pin registered";

$pi->cleanup;

print "\n*** Local: Cleaned up ***\n\n";

$meta = $pi->meta_fetch;

is keys %{ $meta->{objects} }, 0 + $obj_count, "all objects have been removed from registry";
is keys %{ $meta->{pins} }, 0, "all pins have been removed from registry";

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

sub mywait {
    while (1){
        last if -e $f;
        select(undef, undef, undef, 0.2);
    }
}

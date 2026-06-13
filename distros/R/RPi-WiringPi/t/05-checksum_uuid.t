use strict;
use warnings;
use feature 'say';

use lib 't/';

use Data::Dumper;
use RPi::WiringPi;
use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/05-checksum_uuid.t', shm_key => 'rpit');
my $meta = $pi->meta_fetch;

is exists $meta->{objects}{$pi->uuid}, 1, "shared memory has the object's uuid";
is exists $meta->{objects}{$pi->uuid}{proc}, 1, "shared memory has the object's proc";
is exists $meta->{objects}{$pi->uuid}{label}, 1, "shared memory has the object's label";

is ref $meta->{objects}{$pi->uuid}, 'HASH', "object is a hash ref";
is $meta->{objects}{$pi->uuid}{label}, 't/05-checksum_uuid.t', "object's label is correct";
is $meta->{objects}{$pi->uuid}{proc}, $$, "object's proc is ok";

my $c = $pi->checksum;

check_checksum($c, 'checksum');
check_checksum($pi->uuid, 'uuid');

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

sub check_checksum {
    my ($c, $text) = @_;

    is length($c), 32, "'$text' checksum length ok";

    my %valid_chars = map {$_ => 1} (0..9, 'a'..'f');

    my $u_count = 1;

    for (split //, $c){
        is exists $valid_chars{$_}, 1, "'$text' char $_ in position $u_count valid";
        $u_count++;
    }
}

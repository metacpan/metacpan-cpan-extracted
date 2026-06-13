use warnings;
use strict;

use Data::Dumper;
use RPi::WiringPi;

use constant {
    CLEAN_META => 0
};

my $fatal = CLEAN_META ? 0 : 1;

my $pi = RPi::WiringPi->new(fatal_exit => $fatal);

$pi->clean_shared if CLEAN_META;

my $meta = $pi->metadata;

print Dumper $meta;


use strict;
use warnings;
use Test::More tests => 17;
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

can_ok($antenna, 'new');
can_ok($antenna, 'read');
can_ok($antenna, 'write');

can_ok($antenna, 'header');
can_ok($antenna, 'horizontal');
can_ok($antenna, 'vertical');

can_ok($antenna, 'name');
can_ok($antenna, 'gain');
can_ok($antenna, 'gain_dbd');
can_ok($antenna, 'gain_dbi');
can_ok($antenna, 'frequency');
can_ok($antenna, 'frequency_ghz');
can_ok($antenna, 'frequency_mhz');
can_ok($antenna, 'electrical_tilt');
can_ok($antenna, 'comment');

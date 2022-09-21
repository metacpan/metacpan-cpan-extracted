use strict;
use warnings;
use Test::More tests => 23;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $file    = file(file($0)->dir, 'anonymous.msi');
my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

is($antenna->frequency('5555'),        '5555', 'frequency');
is($antenna->frequency_mhz, 5555, 'frequency_mhz');
is($antenna->frequency_ghz, 5.555, 'frequency_ghz');

is($antenna->frequency('5555 MHz'),    '5555 MHz', 'frequency');
is($antenna->frequency_mhz, 5555, 'frequency_mhz');
is($antenna->frequency_ghz, 5.555, 'frequency_ghz');

is($antenna->frequency('5555000 kHz'), '5555000 kHz', 'frequency');
is($antenna->frequency_mhz, 5555, 'frequency_mhz');
is($antenna->frequency_ghz, 5.555, 'frequency_ghz');

is($antenna->frequency('5.555 GHz'),   '5.555 GHz', 'frequency');
is($antenna->frequency_mhz, 5555, 'frequency_mhz');
is($antenna->frequency_ghz, 5.555, 'frequency_ghz');

is($antenna->gain(11.11)      , '11.11', 'gain');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.25, 'gain_dbi');

is($antenna->gain('11.11 dBd'), '11.11 dBd', 'gain');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.25, 'gain_dbi');

is($antenna->gain('11.11 dBi'), '11.11 dBi', 'gain');
is($antenna->gain_dbd,  8.97, 'gain_dbd');
is($antenna->gain_dbi,  11.11, 'gain_dbi');

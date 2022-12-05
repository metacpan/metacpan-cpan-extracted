use strict;
use warnings;
use Test::More tests => 77;
use Test::Number::Delta;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

#delta_within(db_ratio(2),    3.0103, 1e-4, 'db_ratio');

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


is($antenna->gain(11.11), '11.11', 'gain perl number as string');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.26, 'gain_dbi');


is($antenna->gain('11.11'), '11.11', 'gain float');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.26, 'gain_dbi');

is($antenna->gain('11.11 dBd'), '11.11 dBd', 'gain');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.26, 'gain_dbi');

is($antenna->gain('11.11 dBi'), '11.11 dBi', 'gain');
is($antenna->gain_dbd,  8.96, 'gain_dbd');
is($antenna->gain_dbi,  11.11, 'gain_dbi');

is($antenna->gain('(dBi) 11.11'), '(dBi) 11.11', 'gain');
is($antenna->gain_dbd,  8.96, 'gain_dbd');
is($antenna->gain_dbi,  11.11, 'gain_dbi');

is($antenna->gain('(dBd) 11.11'), '(dBd) 11.11', 'gain');
is($antenna->gain_dbd,  11.11, 'gain_dbd');
is($antenna->gain_dbi,  13.26, 'gain_dbi');


is($antenna->gain('.11'), '.11', 'gain implicit leading zero');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');

is($antenna->gain('.11 dBd'), '.11 dBd', 'gain');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');

is($antenna->gain('.11 dBi'), '.11 dBi', 'gain');
is($antenna->gain_dbd,  -2.04, 'gain_dbd');
delta_within($antenna->gain_dbi, 0.11, 1e-14, 'gain_dbi');

is($antenna->gain('(dBi) .11'), '(dBi) .11', 'gain');
is($antenna->gain_dbd,  -2.04, 'gain_dbd');
delta_within($antenna->gain_dbi, 0.11, 1e-14, 'gain_dbi');

is($antenna->gain('(dBd) .11'), '(dBd) .11', 'gain');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');


is($antenna->gain('0.11'), '0.11', 'gain leading zero');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');

is($antenna->gain('0.11 dBd'), '0.11 dBd', 'gain');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');

is($antenna->gain('0.11 dBi'), '0.11 dBi', 'gain');
is($antenna->gain_dbd,  -2.04, 'gain_dbd');
delta_within($antenna->gain_dbi, 0.11, 1e-14, 'gain_dbi');

is($antenna->gain('(dBi) 0.11'), '(dBi) 0.11', 'gain');
is($antenna->gain_dbd,  -2.04, 'gain_dbd');
delta_within($antenna->gain_dbi, 0.11, 1e-14, 'gain_dbi');

is($antenna->gain('(dBd) 0.11'), '(dBd) 0.11', 'gain');
delta_within($antenna->gain_dbd, 0.11, 1e-14, 'gain_dbd');
is($antenna->gain_dbi,  2.26, 'gain_dbi');


is($antenna->gain('11'), '11', 'gain int');
is($antenna->gain_dbd,  11, 'gain_dbd');
is($antenna->gain_dbi,  13.15, 'gain_dbi');

is($antenna->gain('11 dBd'), '11 dBd', 'gain');
is($antenna->gain_dbd,  11, 'gain_dbd');
is($antenna->gain_dbi,  13.15, 'gain_dbi');

is($antenna->gain('11 dBi'), '11 dBi', 'gain');
is($antenna->gain_dbd,  8.85, 'gain_dbd');
is($antenna->gain_dbi,  11, 'gain_dbi');

is($antenna->gain('(dBi) 11'), '(dBi) 11', 'gain');
is($antenna->gain_dbd,  8.85, 'gain_dbd');
is($antenna->gain_dbi,  11, 'gain_dbi');

is($antenna->gain('(dBd) 11'), '(dBd) 11', 'gain');
is($antenna->gain_dbd,  11, 'gain_dbd');
is($antenna->gain_dbi,  13.15, 'gain_dbi');


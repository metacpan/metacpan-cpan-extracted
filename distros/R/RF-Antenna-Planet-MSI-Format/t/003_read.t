use strict;
use warnings;
use Test::More tests => 360 * 2 + 16;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $file    = file(file($0)->dir, 'anonymous.msi');
my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

$antenna->read($file);

isa_ok($antenna->header, 'HASH');
isa_ok($antenna->horizontal, 'ARRAY');
isa_ok($antenna->vertical, 'ARRAY');
is(scalar(@{$antenna->horizontal}), 360, 'sizeof horizontal');
is(scalar(@{$antenna->vertical}), 360, 'sizeof vertical');

is($antenna->name,            'Anonymous-12345', 'name');
is($antenna->frequency,       '2450', 'frequency');
is($antenna->frequency_mhz,   2450, 'frequency_mhz');
is($antenna->frequency_ghz,   2.45, 'frequency_ghz');
is($antenna->gain,            '7.69 dBd', 'gain');
is($antenna->gain_dbd,        7.69, 'gain_dbd');
is($antenna->gain_dbi,        9.84, 'gain_dbi');
is($antenna->electrical_tilt, '0', 'electrical_tilt');
is($antenna->comment,         'This is an anonymous antenna file', 'comment');

foreach my $angle (0 .. 359) {
  is($antenna->horizontal->[$angle]->[0]+0, $angle);
  is($antenna->vertical->[$angle]->[0]+0, $angle);
}

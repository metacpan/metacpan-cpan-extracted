use strict;
use warnings;
use Test::More tests => 16;
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');
my $blob = join('', <DATA>);

$antenna->read(\$blob);

isa_ok($antenna->header, 'HASH');

is($antenna->name,            'ASSUMED_NAME', 'name');
is($antenna->frequency,       '2450', 'frequency');
is($antenna->frequency_mhz,   2450, 'frequency_mhz');
is($antenna->frequency_ghz,   2.45, 'frequency_ghz');
is($antenna->gain,            '7.69 dBd', 'gain');
is($antenna->gain_dbd,        7.69, 'gain_dbd');
is($antenna->gain_dbi,        9.84, 'gain_dbi');
is($antenna->comment,         'Assumed Name Test', 'comment');

isa_ok($antenna->horizontal, 'ARRAY');
isa_ok($antenna->vertical, 'ARRAY');
is(scalar(@{$antenna->horizontal}), 1, 'sizeof horizontal');
is(scalar(@{$antenna->vertical}), 1, 'sizeof vertical');

my $out='';
$antenna->write(\$out);
is($out, "NAME $blob");

__DATA__
ASSUMED_NAME
FREQUENCY 2450
GAIN 7.69 dBd
COMMENT Assumed Name Test
HORIZONTAL 1
0 0
VERTICAL 1
0 0

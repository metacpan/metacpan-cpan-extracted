use strict;
use warnings;
use Test::More tests => 10;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

my $file = join "", <DATA>;

$antenna->read(\$file);

isa_ok($antenna->header, 'HASH');
isa_ok($antenna->horizontal, 'ARRAY');
isa_ok($antenna->vertical, 'ARRAY');
is(scalar(@{$antenna->horizontal}), 2, 'sizeof horizontal');
is(scalar(@{$antenna->vertical}), 2, 'sizeof vertical');

is($antenna->name,            'My Name', 'name');
is($antenna->frequency,       '1234', 'frequency');
is($antenna->gain,            '12.3', 'gain');

__DATA__
NAME My Name
GAIN 12.3
FREQUENCY 1234
HORIZONTAL 2
0 0
180 12.3
VERTICAL 2
0 1
180 11.2

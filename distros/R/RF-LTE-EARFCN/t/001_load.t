use strict;
use warnings;

use Test::More tests => 21;
BEGIN { use_ok('RF::LTE::EARFCN') };

my $rf = RF::LTE::EARFCN->new;

isa_ok($rf, 'RF::LTE::EARFCN');
can_ok($rf, 'new');
can_ok($rf, 'channel');
can_ok($rf, 'channel_type');
can_ok($rf, 'band');
can_ok($rf, 'fdl');
can_ok($rf, 'ful');
can_ok($rf, 'fs');

is($rf->channel(5110), 5110, 'channel');
is($rf->channel_type, 'dl', 'channel_type');
is($rf->band, '12', 'band');
is($rf->fdl, 739, 'fdl');
is($rf->fs, 30, 'fs');
is($rf->ful, 709, 'ful');

#NOTE 2: Restricted to E-UTRA operation when carrier aggregation is configured. 
is($rf->channel(9660), 9660, 'channel for downlink only band 29');
is($rf->channel_type, 'dl', 'channel_type');
is($rf->band, '29', 'band');
is($rf->fdl, 717, 'fdl');
is($rf->fs, 'n/a', 'fs');   #expect error
is($rf->ful, 'n/a', 'ful'); #expect error

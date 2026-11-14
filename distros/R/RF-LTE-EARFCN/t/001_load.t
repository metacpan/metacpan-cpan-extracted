use strict;
use warnings;

use Test::More tests => 65;
BEGIN { use_ok('RF::LTE::EARFCN') };

my $rf = RF::LTE::EARFCN->new;

isa_ok($rf, 'RF::LTE::EARFCN');
can_ok($rf, 'new');
can_ok($rf, 'channel');
can_ok($rf, 'channel_type');
can_ok($rf, 'channel_offset');
can_ok($rf, 'band');
can_ok($rf, 'fdl');
can_ok($rf, 'ful');
can_ok($rf, 'fs');

is($rf->channel(5110), 5110, 'set channel');
is($rf->channel, 5110, 'read channel');
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
is($rf->fs, undef, 'fs');   #expect error
is($rf->ful, undef, 'ful'); #expect error

#Test Case from Google AI

is($rf->channel(7710), 7710, 'channel: 7710 - set channel');
is($rf->channel, 7710, 'channel: 7710 - read channel');
is($rf->channel_type, 'dl', 'channel: 7710 - channel_type');
is($rf->band, '24', 'channel: 7710 - band');
is($rf->fdl, 1526, 'channel: 7710 - fdl');
is($rf->fs, -101.5, 'channel: 7710 - fs');
is($rf->ful, 1627.5, 'channel: 7710 - ful');

{
  local $RF::LTE::EARFCN::BAND_TABLE->[21]->[$RF::LTE::EARFCN::BAND_TABLE_INDEX_ful_low]         = 1645.5; #Band 24 fs option -120.5
  local $RF::LTE::EARFCN::BAND_TABLE->[21]->[$RF::LTE::EARFCN::BAND_TABLE_INDEX_range_nul_lower] = 25900;  #Band 24 fs option -120.5
  is($rf->channel(7710), 7710, 'fs option -120.5, channel: 7710 - set channel');
  is($rf->channel, 7710, 'fs option -120.5, channel: 7710 - read channel');
  is($rf->channel_type, 'dl', 'fs option -120.5, channel: 7710 - channel_type');
  is($rf->band, '24', 'fs option -120.5, channel: 7710 - band');
  is($rf->fdl, 1526, 'fs option -120.5, channel: 7710 - fdl');
  is($rf->fs, -120.5, 'fs option -120.5, channel: 7710 - fs');
  is($rf->ful, 1646.5, 'fs option -120.5, channel: 7710 - ful');
}

is($rf->channel(25785), 25785, 'channel: 25785 - set channel');
is($rf->channel, 25785, 'channel: 25785 - read channel');
is($rf->channel_type, 'ul', 'channel: 25785 - channel_type');
is($rf->band, '24', 'channel: 25785 - band');
is($rf->fs, -101.5, 'channel: 25785 - fs');
is($rf->ful, 1635, 'channel: 25785 - ful');
is($rf->fdl, 1533.5, 'channel: 25785 - fdl');

is($rf->channel(7785), 7785, 'channel: 7785 - set channel');
is($rf->channel, 7785, 'channel: 7785 - read channel');
is($rf->channel_type, 'dl', 'channel: 7785 - channel_type');
is($rf->band, '24', 'channel: 7785 - band');
is($rf->fs, -101.5, 'channel: 7785 - fs');
is($rf->ful, 1635, 'channel: 7785 - ful');
is($rf->fdl, 1533.5, 'channel: 7785 - fdl');

{
  #Shifted Uplink-to-Downlink Pairing. Under default −101.5 MHz spacing, a paired uplink EARFCN N_UL and downlink EARFCN N_DL are separated by exactly 18,000. When the −120.5 MHz spacing is invoked, the extra 19.0 MHz frequency separation shifts the pairing difference to 18,190.
  #Restricted Sub-Band Pairing. Band 24 uses variable duplex spacing to accommodate US L-Band regulatory limits near GPS spectrum. Downlink operation is restricted to the lower 10 MHz portion (1526–1536 MHz, corresponding to N_DL 7710–7810), while uplink is split into a lower block (1627.5–1637.5 MHz) and an upper block (1646.5–1656.5 MHz). Invoking −120.5 MHz pairs that same lower downlink block with the upper uplink block N_UL 25900–26000.

  local $RF::LTE::EARFCN::BAND_TABLE->[21]->[$RF::LTE::EARFCN::BAND_TABLE_INDEX_ful_low]         = 1645.5; #Band 24 fs option -120.5 = ful_low + 19MHz
  local $RF::LTE::EARFCN::BAND_TABLE->[21]->[$RF::LTE::EARFCN::BAND_TABLE_INDEX_range_nul_lower] = 25890;  #Band 24 fs option -120.5 = range_nul_lower + 190
  is($rf->channel(25975), 25975, 'channel: 25975 - set channel');
  is($rf->channel, 25975, 'channel: 25975 - read channel');
  is($rf->channel_type, 'ul', 'channel: 25975 - channel_type');
  is($rf->band, '24', 'channel: 25975 - band');
  is($rf->fs, -120.5, 'channel: 25975 - fs');
  is($rf->ful, 1654, 'channel: 25975 - ful');
  is($rf->fdl, 1533.5, 'channel: 25975 - fdl');

  is($rf->channel(7785), 7785, 'channel: 7785 - set channel');
  is($rf->channel, 7785, 'channel: 7785 - read channel');
  is($rf->channel_type, 'dl', 'channel: 7785 - channel_type');
  is($rf->band, '24', 'channel: 7785 - band');
  is($rf->fs, -120.5, 'channel: 7785 - fs');
  is($rf->ful, 1654, 'channel: 7785 - ful');
  is($rf->fdl, 1533.5, 'channel: 7785 - fdl');
}

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('RF::LTE::EARFCN') };

my $rf = RF::LTE::EARFCN->new;
isa_ok($rf, 'RF::LTE::EARFCN');

{
  local $@;
  eval '$rf->channel(undef)';
  my $error = $@;
  ok($error, '$rf->channel(undef)');
  like($error, qr/channel required/, '$rf->channel(undef)');
}
{
  local $@;
  eval '$rf->channel(-1)';
  my $error = $@;
  ok($error, '$rf->channel(-1)');
  like($error, qr/channel must be zero or greater/, '$rf->channel(-1)');
}
{
  local $@;
  $rf->channel(999999);
  eval '$rf->channel_type';
  my $error = $@;
  ok($error, '$rf->channel(999999)');
  like($error, qr/table entry not found/, '$rf->channel(999999)');
}

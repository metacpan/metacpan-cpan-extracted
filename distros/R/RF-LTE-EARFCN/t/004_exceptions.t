use strict;
use warnings;

use Test::More tests => 15;
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
{
  is($RF::LTE::EARFCN::FS_TABLE{'1'}, 190);
  is($rf->channel(0), 0, '$rf->channel(0)');
  is($rf->fs, 190);

  
  local %RF::LTE::EARFCN::FS_TABLE = %RF::LTE::EARFCN::FS_TABLE;
  delete($RF::LTE::EARFCN::FS_TABLE{'1'});

  is($rf->channel(0), 0, '$rf->channel(0)');

  local $@;
  eval '$rf->fs';
  my $error = $@;
  ok($error, 'delete %RF::LTE::EARFCN::FS_TABLE');
  like($error, qr/frequency separation not found/, 'delete %RF::LTE::EARFCN::FS_TABLE');
}
is($RF::LTE::EARFCN::FS_TABLE{'1'}, 190);


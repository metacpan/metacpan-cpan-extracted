use Test::More qw/no_plan/;

use Outthentic::DSL;

ok 1, 'Module loaded';

my $otx = Outthentic::DSL->new({
  debug_mod => $ENV{OTX_DEBUG},
  output => 'OK'
});

$otx->validate('OK');

#ok(1, "OK validated");


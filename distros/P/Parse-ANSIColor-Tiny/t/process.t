use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

# process() makes no changes if nothing is configured

eq_or_diff
  [$p->process(qw(red on_white reverse))],
  [qw(red on_white reverse)],
  'no changes';

# process() calls process_reverse if configured

$p = new_ok($mod, [auto_reverse => 1]);

eq_or_diff
  [$p->process(qw(red on_white reverse))],
  [qw(on_red white)],
  'reversed';

# reverse is currently the only possibility for process()

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The alerts option carries two shapes, and 0.07 confused them: the POLICY
# hash (every, group_wait, repeat_interval) was handed to _seam, which turns
# any hashref without read/write/delete into a static reader, so a host that
# set a cadence got a reader that read nothing and an alerts page saying
# "No alert rules yet" over a configuration store full of rules. The seam
# and the policy are told apart here, and the policy still parses.

use Punk::Plugin::Observe ();

my $seam   = \&Punk::Plugin::Observe::_seam;
my $policy = \&Punk::Plugin::Observe::_alerts_policy_only;
my $opts   = \&Punk::Plugin::Observe::_alerts_opts;

ok($policy->({ every => '@every 30s' }), 'a cadence alone is the policy');
ok($policy->({ every => '@every 30s', group_wait => '30s', repeat_interval => '15m' }), 'all three keys are the policy');
ok(!$policy->({}), 'an empty hash is not');
ok(!$policy->({ read => sub { } }), 'a reader is not');
ok(!$policy->({ read => sub { }, every => '@every 1m' }), 'a reader with a cadence beside it is not');
ok(!$policy->({ rules => [] }), 'static rules are not');
ok(!$policy->({ every => '@every 30s', extra => 1 }), 'an unknown key beside the cadence is not (the seam decides)');
ok(!$policy->(sub { }), 'a coderef is not');
ok(!$policy->(undef), 'nor is nothing');

is($seam->(undef), undef, 'no option: no seam');
is(ref $seam->(sub { })->{read}, 'CODE', 'a coderef is a reader');
is_deeply($seam->({ read => 'r', write => 'w' }), { read => 'r', write => 'w' }, 'a read/write hash is itself');
is(ref $seam->({ rules => [] })->{read}, 'HASH', 'static rules become a static reader');

my $o = $opts->({ alerts => { every => '@every 45s', group_wait => '10s', repeat_interval => '15m' } });
is($o->{every}, '@every 45s', 'the policy cadence is read');
is($o->{group_wait_ns}, 10_000_000_000, 'and the group wait');
is($o->{repeat_ns}, 15 * 60 * 1_000_000_000, 'and the repeat interval');
$o = $opts->({ alerts => { read => sub { } } });
is($o->{every}, '@every 30s', 'a seam leaves the policy at its defaults');

done_testing();

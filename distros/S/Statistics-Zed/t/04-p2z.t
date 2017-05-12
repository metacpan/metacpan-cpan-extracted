use strict;
use warnings;
use Test::More tests => 15;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::Zed') };

my $zed = Statistics::Zed->new(ccorr => 1, tails => 2,);

my $p2z = 1.5000;

my $ret;

eval { $ret = $zed->p2z(value => .066807, tails => 1);};
ok(!$@, $@);
ok(equal($ret, $p2z), "p2z  $ret != $p2z");

eval { $ret = $zed->p2z(value => .133610, tails => 2);};
ok(!$@, $@);
ok(equal($ret, $p2z), "p2z  $ret != $p2z");

eval { $ret = $zed->p2z(value => 6.6807e-2, tails => 1);};
ok(!$@, $@);
ok(equal($ret, $p2z), "p2z  $ret != $p2z");

$ret = undef;
eval{$ret = $zed->p2z(tails => 2)}; # fails?
ok($@);
ok(!$ret, 'Failed to reject undefined value to p2z');

eval {$ret = $zed->p2z(value => 'x', tails => 2);}; # fails?
ok($@);
ok(!$ret, 'Failed to reject non-numeric value to p2z');

eval {$ret = $zed->p2z(value => 2, tails => 2);}; # fails?
ok($@);
ok(!$ret, 'Failed to reject non-proportional value to p2z');

eval {$ret = $zed->p2z(value => 1, tails => 2);};
ok(!$@, $@);
ok($ret == 0, 'Failed to accept unity value to p2z');

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
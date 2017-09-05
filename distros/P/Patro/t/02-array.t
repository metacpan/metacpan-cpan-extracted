use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.010;
use Scalar::Util 'reftype';

my $r0 = [ 1, 2, 3, 4 ];

ok($r0 && ref($r0) eq 'ARRAY', 'created remote var');

my $cfg = patronize($r0);
ok($cfg, 'got config for patronize array ref');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($r1) = Patro->new($cfgstr)->getProxies;
ok($r1, 'client as boolean, loaded from config string');
is(CORE::ref($r1), 'Patro::N1', 'client ref');
is(Patro::ref($r1), 'ARRAY', 'remote ref');
is(Patro::reftype($r1), 'ARRAY', 'remote reftype');

my $c = Patro::client($r1);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';

is($r1->[3], 4, 'array access');

push @$r1, [15,16,17], 18;
is($r1->[-3], 4, 'push to remote array');

$r1->[2] = 19;
is($r1->[2], 19, 'set remote array');
if ($THREADED) {
    is($r0->[-3], 4, 'local update affects remote object');
    is($r0->[2], 19, 'local update affects remote object');
}

is(shift @$r1, 1, 'shift from remote array');

unshift @$r1, (25 .. 31);
is($r1->[6], 31, 'unshift to remote array');
is($r1->[7], 2, 'unshift to remote array');

is(pop @$r1, 18, 'pop from remote array');

my $r6 = $r1->[10];
is(CORE::ref($r6), 'Patro::N1', 'proxy handle for nested remote obj');
is(Patro::ref($r6), 'ARRAY', 'got remote ref type');

done_testing;

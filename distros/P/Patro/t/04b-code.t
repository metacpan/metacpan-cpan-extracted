use Test::More;
use Patro ':test', ':code';
use Scalar::Util 'reftype', 'refaddr';
use Carp 'verbose';
use 5.012;

my $dispatch = {
    abc => 12,
    foo => sub { 42 },
    bar => sub { 19 + $_[0] * $_[1] },
    baz => sub { return ++$_[0]->{abc} }
};

my $cfg = patronize($dispatch);
ok($cfg, 'got config for patronize hash');
my ($r1,$null) = Patro->new($cfg)->getProxies;
ok($r1, 'client as boolean');
ok(!$null, 'extra client as boolean');
is(CORE::ref($r1), 'Patro::N1', 'client ref');
is(Patro::ref($r1), 'HASH', 'remote ref');
is(Patro::reftype($r1),'HASH', 'remote reftype');
ok(tied(%$r1), 'proxy var is tied when deref as hash');

my $c = Patro::client($r1);
ok($c, 'retrieved client object');
my $THREADED = $c->{config}{style} eq 'threaded';


is(CORE::ref($r1->{foo}), 'Patro::N3', 'remote dispatch entry');
is(Patro::ref($r1->{foo}), 'CODE', 'remote dispatch entry');

done_testing;


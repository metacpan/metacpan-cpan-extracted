use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.012;
use Scalar::Util 'reftype';

# Test::More::is_deeply($x,$y) doesn't work with proxies.
# Use  Test::More::is(xjoin($x),xjoin($y)) instead

my $r0 = ArrayThing->new( 1, 2, 3, 4 );

ok($r0 && ref($r0) eq 'ArrayThing', 'created remote var');

my $cfg = patronize($r0);
ok($cfg, 'got config for patronize array ref');

my ($r1) = Patro->new($cfg)->getProxies;

ok($r1, 'client as boolean');
is(CORE::ref($r1), 'Patro::N1', 'client ref');
is(Patro::ref($r1), 'ArrayThing', 'remote ref');
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

ok(18 == $r1->reverse, 'called method on remote obj');
is(xjoin($r1), "[[15,16,17],4,19,2,31,30,29,28,27,26,25]",
   'reverse operation ok');
if ($THREADED) {
    is(xjoin($r0),xjoin($r1),"local and remote object match after function call");
}
is($r1->[4],$r1->get(4), 'remote function call ok');
ok_threaded($r0->get(-2) == $r1->get(-2),
	    'local function call same as remote function call');

my @x = $r1->context_dependent;
my $x = $r1->context_dependent;
is($x, $r1->get(1), 'context respected in scalar context');
is(xjoin(\@x),xjoin([5,6,7]), 'context respected in list context');

done_testing;

# ArrayThing - a blessed ARRAY reference with a couple
# of methods to exercise remote manipulation

sub ArrayThing::new {
    my ($pkg,@list) = @_;
    return bless [ @list ], $pkg;
}

sub ArrayThing::reverse {
    my $self = shift;
    @$self = reverse @$self;
    return 18;
}

sub ArrayThing::increment {
    my ($self,$n) = @_;
    $n //= 1;
    $_ += $n for @$self;
    return;
}

sub ArrayThing::get {
    my ($self,$index) = @_;
    return $self->[$index];
}

sub ArrayThing::context_dependent {
    my $self = shift;
    return wantarray ? (5,6,7) : $self->[1];
}

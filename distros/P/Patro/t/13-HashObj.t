use Test::More;
use Carp 'verbose';
use Patro ':test';
use Scalar::Util 'reftype';
use 5.012;

my $r0 = HashThing->new( abc => "xyz", def => "foo",
	   ghi => { jkl => [ 'm','n','o','p',['qrs','tuv']],
		    wxy => 123 } );

ok($r0 && ref($r0) eq 'HashThing', 'created remote var');

my $cfg = patronize($r0);
ok($cfg, 'got config for patronize hash');
my ($r1,$null) = Patro->new($cfg)->getProxies;
ok($r1, 'client as boolean');
ok(!$null, 'extra client as boolean');
is(CORE::ref($r1), 'Patro::N1', 'client ref');
is(Patro::ref($r1), 'HashThing', 'remote ref');
is(Patro::reftype($r1),'HASH', 'remote reftype');
ok(tied(%$r1), 'proxy var is tied when deref as hash');

my $c = Patro::client($r1);
ok($c, 'retrieved client object');
my $THREADED = $c->{config}{style} eq 'threaded';

is($r1->{def}, 'foo', 'hash access');
$r1->{bar} = 456;
is($r1->{bar}, 456, 'add to remote hash');
if ($THREADED) {
    is($r0->{bar}, 456, 'update to remote hash changes local hash');
    $r0->{bar} = 409;
    is($r1->{bar}, 409, 'update to local hash changes remote hash');
}


is($r1->{ghi}{wxy}, 123, 'hash deep access');
$r1->{ghi}{wxy} = 789;
is($r1->{ghi}{wxy}, 789, 'add to deep remote hash');
is($r1->{ghi}{jkl}[2], 'o', 'deep update did not update other elements');
ok(exists $r1->{ghi}, '1st level key exists');
ok(exists $r1->{ghi}{jkl}, '2nd level key exists');
is($r1->{ghi}{jkl}[4][1], 'tuv', 'deep update did not update other elem');
is(Patro::ref($r1->{ghi}{jkl}), 'ARRAY', '2nd level val is ARRAY ref');

is(delete $r1->{abc}, 'xyz', 'delete from remote hash');
is($r1->{abc}, undef, 'delete from remote hash cleared key');
ok(!exists $r1->{abc}, 'delete from remote hash makes exists fail');
if ($THREADED) {
    is($r0->{ghi}{wxy}, 789, 'deep update to remote obj changes local obj');
    ok(!exists $r1->{abc}, 'delete from remote obj changes local obj');
}

is(eval{$r1->uckeys}, 72, 'called remote method');
is($@,'', 'remote method did not cause an error');
ok(!exists($r1->{ghi}) && exists($r1->{GHI}),
   'remote object call affects remote object');
ok_threaded(exists $r0->{GHI}, 'remote object call affects local object');

done_testing;

sub HashThing::new {
    my ($pkg,@list) = @_;
    return bless +{ @list }, $pkg;
}

sub HashThing::uckeys {
    my ($self) = @_;
    my %kk = map { $_ => uc $_ } keys %$self;
    while (my ($k1,$k2) = each %kk) {
	next if $k1 eq $k2;
	$self->{$k2} = delete $self->{$k1};
    }
    return 72;
}





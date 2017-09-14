use Test::More;
use Patro ':test';
use Scalar::Util 'reftype';
use 5.010;


my $foo = "42";
my $obj0 = \$foo;
my $obj = \$obj0;

ok($obj && ref($obj) eq 'REF', 'create remote ref');
my $cfg = patronize($obj);
ok($cfg, 'got server config');

my ($proxy) = 1 ? Patro->new($cfg)->getProxies : $obj;
ok($proxy, 'proxy as boolean');
ok(Patro::ref($proxy) eq 'REF', 'remote ref')
    or diag "Patro::ref was ", Patro::ref($proxy);

ok(Patro::N6->can('VERSION'), 'Patro::N6 can VERSION');

ok(CORE::ref($proxy) eq 'Patro::N6', 'proxy ref is Patro::N6');
my $can = eval { $proxy->can('bogus') };
ok(CORE::ref($proxy) eq 'Patro::N6', 'proxy ref is Patro::N6');

ok(!$can && !$@, 'ref UNIVERSAL::can call ok') or ::xdiag([$can,$@]);

ok(Patro::reftype($proxy) eq 'REF', 'remote reftype');

is($$$proxy, 42, 'scalar access');

$$$proxy = 456;
is($$$proxy, 456, 'update scalar');
my $c = Patro::client($proxy);
 SKIP: {
     if ($c->{config}{style} ne 'threaded') {
	 skip('update to proxy won\'t affect remote on non-threaded server', 1);
     }
     ok($$$obj == 456, 'update proxy changes remote object');
}

$$$proxy += 15;
is($$$proxy, 471, 'update scalar with assignment operator');
 SKIP: {
     if ($c->{config}{style} ne 'threaded') {
	 skip("update to proxy won't affect remote on non-threaded server", 1);
     }
     ok($$$obj == 471, 'update proxy changes remote object');
}

done_testing;

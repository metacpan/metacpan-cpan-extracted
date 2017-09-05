use Test::More;
use Patro ':test';
use Scalar::Util 'reftype';
use 5.010;

my $main_pid = $$;
$SIG{ALRM} = sub { warn "SIGALRM! \@ ",scalar localtime; };

my $foo = "42";
my $obj = \$foo;

ok($obj && ref($obj) eq 'SCALAR', 'create remote ref');
my $cfg = patronize($obj);
ok($cfg, 'got server config');

my ($proxy) = Patro->new($cfg)->getProxies;
ok($proxy, 'proxy as boolean');
ok(Patro::ref($proxy) eq 'SCALAR', 'remote ref')
    or diag "Patro::ref was ", Patro::ref($proxy);
ok(Patro::reftype($proxy) eq 'SCALAR', 'remote reftype');

is($$proxy, 42, 'scalar access');

$$proxy = 456;
is($$proxy, 456, 'update scalar');
ok_threaded($$obj == 456, 'update proxy changes remote object');

$$proxy += 15;
is($$proxy, 471, 'update scalar with assignment operator');
ok_threaded($$obj == 471, 'update proxy changes remote object');

done_testing;

use Test::More;
use Patro ':test';
use Scalar::Util 'reftype';

my $main_pid = $$;
$SIG{ALRM} = sub { warn "SIGALRM! \@ ",scalar localtime; };

my $foo = "42";
my $obj = \$foo;
bless $obj, 'ScalarThing';

ok($obj && ref($obj) eq 'ScalarThing', 'create remote ref');
my $cfg = patronize($obj);
ok($cfg, 'got server config');

my ($proxy) = Patro->new($cfg)->getProxies;
ok($proxy, 'proxy as boolean');
ok(Patro::ref($proxy) eq 'ScalarThing', 'remote ref')
    or diag "Patro::ref was ", Patro::ref($proxy);
ok(Patro::reftype($proxy) eq 'SCALAR', 'remote reftype');

is($$proxy, 42, 'scalar access');

$$proxy = 456;
is($$proxy, 456, 'update scalar');
my $c = Patro::client($proxy);
 SKIP: {
     if ($c->{config}{style} ne 'threaded') {
	 skip("update to proxy won't affect remote on non-threade server", 1);
     }
     ok($$obj == 456, 'update proxy changes remote object');
}

$$proxy += 15;
is($$proxy, 471, 'update scalar with assignment operator');
 SKIP: {
     if ($c->{config}{style} ne 'threaded') {
	 skip("update to proxy won't affect remote on non-threade server", 1);
     }
     ok($$obj == 471, 'update proxy changes remote object');
}

is($proxy->hello, 'hello', 'proxy method call ok');
my $x = eval { $proxy->goodbye };
is($x, undef, 'proxy undefined method call no good val returned');
ok($@ =~ /goodbye/ && $@ =~ /ScalarThing/,
   'proxy undefined method call raised error');

ok($proxy->can('hello'), '$proxy->can ok on valid method name');
ok(!$proxy->can('later'), '$proxy->can ok on invalid method name');
ok(eval { Patro::N2->can('later'); 1 }, 'Patro::N2->can ok');

done_testing;


sub ScalarThing::hello {
    return "hello";
}

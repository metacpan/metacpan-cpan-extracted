use Test::More;
use Patro ':test';
use strict;
use warnings;

if (!eval "use Math::BigInt;1") {
    ok(1,"SKIP - Math::BigInt not available");
    done_testing();
    exit;
}

my $b0 = Math::BigInt->new(42);
my $b1 = Math::BigInt->new(19);
my $b2 = Math::BigInt->new(4);
my $cfg = patronize($b0,$b1,$b2);
ok($cfg, "got config for two Math::BigInt's");
   
my ($p0,$p1,$p2) = Patro->new($cfg)->getProxies;
ok($p0 && $p1, "got proxies");

# !!! ok($p0+$p1==61,...) works, but
#     is($p0+$p1,61,...) compares 61 with "Patro::N1=REF(...)"
ok($p0 + $p1 == 42 + 19, 'proxy operation');
is("" . ($p0 * $p1), 42 * 19, "proxy operation");
ok($p0 * $p1 == 42 * 19, 'proxy operation');
ok($p0 / $p1 == int(42/19), 'operation on proxy integers respects int');

my $b3 = 0 + $b2;
my $p3 = eval { $p2->bfac };
is($@, '', 'proxy method call did not throw exception');
is($p3, $b3->bfac, 'proxy method call');

done_testing;

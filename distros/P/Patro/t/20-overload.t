use Test::More;
use Patro ':test';
use strict;
use warnings;

if (!eval "use Math::BigInt; Math::BigInt->VERSION >= 1.997" &&
    $threads::threads) {

    # Math::BigInt prior to 1.997 has bug for shared objects
    ok(1,"SKIP - Math::BigInt not available");
    diag "Overload test requires Math::BigInt 1.997";
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
is($p2->VERSION, $b2->VERSION, '$proxy->VERSION ok');
ok($b2->isa('Math::BigInt') && !$b2->isa('Poodle'), 'Math::BigInt isa check');
is($p2->isa('Math::BigInt'), $b2->isa('Math::BigInt'), '$proxy->isa ok');
is($p2->isa('Poodle'), $b2->isa('Poodle'), '$proxy->isa ok');

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

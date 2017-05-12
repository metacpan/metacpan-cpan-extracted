use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::XS;

my $var = 10;
ok(!Panda::XS::sv_payload_exists($var));
Panda::XS::sv_payload_attach($var, 20);
ok(Panda::XS::sv_payload_exists($var));
is($var, 10);
is(Panda::XS::sv_payload($var), 20);

{
    my $payload = {a => 1};
    $var = "jopa";
    ok(Panda::XS::sv_payload_exists($var));
    Panda::XS::sv_payload_attach($var, $payload);
    cmp_deeply(Panda::XS::sv_payload($var), {a => 1});
}
ok(Panda::XS::sv_payload_exists($var));
cmp_deeply(Panda::XS::sv_payload($var), {a => 1});

Panda::XS::sv_payload_detach($var);
ok(!Panda::XS::sv_payload_exists($var));
# RV test
my $var_rv = bless {aaa => "aaa", bbb => "bbb"},"someclass";
my $some_class = bless {ccc => "ccc"}, "someclass2";
ok(!Panda::XS::rv_payload_exists($var_rv));
Panda::XS::rv_payload_attach($var_rv, $some_class);
ok(Panda::XS::rv_payload_exists($var_rv));

my $dTemp = $var_rv;
ok(Panda::XS::rv_payload($dTemp));
{
    my $payload = {a => 1};
    bless $var_rv,"numberclass";
    ok(Panda::XS::rv_payload_exists($var_rv));
    Panda::XS::rv_payload_attach($var_rv, $payload);
    cmp_deeply(Panda::XS::rv_payload($var_rv), {a => 1});
}
ok(Panda::XS::rv_payload_exists($var_rv));
cmp_deeply(Panda::XS::rv_payload($var_rv), {a => 1});

Panda::XS::rv_payload_detach($var_rv);
ok(!Panda::XS::rv_payload_exists($var_rv));
# ANY test
my $var_s = 10;
my $var_r = {};

ok (! Panda::XS::any_payload_exists($var_s));
ok (! Panda::XS::any_payload_exists($var_r));

Panda::XS::any_payload_attach($var_s,"test scalar");
Panda::XS::any_payload_attach($var_r,"test ref value");

ok ( Panda::XS::any_payload_exists($var_s));
ok ( Panda::XS::any_payload_exists($var_r));

my $rTemp = $var_r;
ok( Panda::XS::any_payload($rTemp));
{
    my $payload = {Test => 22};
    $var_r = [];
    $var_s = "not 10";
    ok(!Panda::XS::any_payload_exists($var_r));
    ok(Panda::XS::any_payload_exists($var_s));

    Panda::XS::any_payload_attach($var_r, $payload);
    Panda::XS::any_payload_attach($var_s, $payload);

    cmp_deeply( Panda::XS::any_payload($var_r), { Test => 22 } );
    cmp_deeply( Panda::XS::any_payload($var_s), { Test => 22 } );
}

ok ( Panda::XS::any_payload_exists($var_s));
ok ( Panda::XS::any_payload_exists($var_r));

Panda::XS::any_payload_detach($var_r);
Panda::XS::any_payload_detach($var_s);

ok (! Panda::XS::any_payload_exists($var_s));
ok (! Panda::XS::any_payload_exists($var_r));

done_testing();
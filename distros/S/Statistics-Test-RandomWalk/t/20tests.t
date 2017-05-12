use strict;
use warnings;
use Test::More tests => 16;
use Params::Util qw/_ARRAY/;
BEGIN { use_ok('Statistics::Test::RandomWalk') };

my $t = Statistics::Test::RandomWalk->new();
isa_ok($t, 'Statistics::Test::RandomWalk');

eval {
    $t->set_data(
        [map rand(), 1..10000]
    );
};
ok(!$@);

ok(ref($t->{data}) eq 'ARRAY');
ok(@{$t->{data}} == 10000);

my ($alpha, $got, $exp);
eval { ($alpha, $got, $exp) = $t->test(10); };
ok(!$@);
ok(_ARRAY($alpha));
ok(_ARRAY($got));
ok(_ARRAY($exp));

my $str = $t->data_to_report($alpha, $got, $exp);
ok(defined $str and length($str));

eval {
    $t->set_data(
        sub { map rand(), 1..100 },
        100
    );
};
ok(!$@);

eval { ($alpha, $got, $exp) = $t->test(20); };
ok(!$@);
ok(_ARRAY($alpha));
ok(_ARRAY($got));
ok(_ARRAY($exp));

$str = $t->data_to_report($alpha, $got, $exp);
ok(defined $str and length($str));


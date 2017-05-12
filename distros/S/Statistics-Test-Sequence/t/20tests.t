use strict;
use warnings;
use Test::More tests => 14;
BEGIN { use_ok('Statistics::Test::Sequence') };

my $t = Statistics::Test::Sequence->new();
isa_ok($t, 'Statistics::Test::Sequence');

eval {
    $t->set_data(
        [map rand(), 1..10000]
    );
};
ok(!$@);

ok(ref($t->{data}) eq 'ARRAY');
ok(@{$t->{data}} == 10000);

my ($res, $bins, $exp);
eval { ($res, $bins, $exp) = $t->test(); };
ok(!$@);
ok(defined $res);
ok(ref($bins) eq 'ARRAY');
ok(ref($exp) eq 'ARRAY');

eval {
    $t->set_data(
        sub { map rand(), 1..100 },
        100
    );
};
ok(!$@);

eval { ($res, $bins, $exp) = $t->test(); };
ok(!$@);
ok(defined $res);
ok(ref($bins) eq 'ARRAY');
ok(ref($exp) eq 'ARRAY');


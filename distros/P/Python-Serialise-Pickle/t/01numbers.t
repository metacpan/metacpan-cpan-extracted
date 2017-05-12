use Test::More qw(no_plan);

use_ok('Python::Serialise::Pickle');

ok(my $ps = Python::Serialise::Pickle->new('t/numbers'));

my $value;

is($ps->load(),1234);
is($ps->load(),-1234);
is($ps->load(),1.234);
is($ps->load(),-1.234);

# todo LONGS


ok(my $pw = Python::Serialise::Pickle->new('>t/tmp'));
ok($pw->dump(1234));
ok($pw->dump(-1234));
ok($pw->dump(1.234));
ok($pw->dump(-1.234));
ok($pw->close());


ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));

is($pr->load(),1234);
is($pr->load(),-1234);
is($pr->load(),1.234);
is($pr->load(),-1.234);


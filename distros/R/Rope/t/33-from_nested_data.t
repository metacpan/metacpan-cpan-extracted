use Test::More;

use Rope;

my $data = {
	a => 1,
	b => 2,
	c => 3,
	d => {
		one => 1,
		two => 2,
		three => 3,
	},
	e => [{ one => 1, two => 2, three => 3 }]
};

my $r = Rope->from_nested_data($data);

is($r->{a}, 1);
is($r->{b}, 2);
is($r->{c}, 3);

is($r->{d}->{one}, 1);
is($r->{d}->{two}, 2);
is($r->{d}->{three}, 3);

is_deeply($r->{e}->[0]->{one}, 1);

my $r = Rope->from_nested_data($data, { use => ["Rope::Autoload"] });

is($r->a, 1);
is($r->b, 2);
is($r->c, 3);

is($r->d->one, 1);
is($r->d->two, 2);
is($r->d->three, 3);

is_deeply($r->e->[0]->one, 1);

$r = Rope->from_nested_data($data, { use => ["Rope::Monkey"] });

is($r->a, 1);
is($r->b, 2);
is($r->c, 3);

is($r->d->one, 1);
is($r->d->two, 2);
is($r->d->three, 3);

is_deeply($r->e->[0]->one, 1);

ok(1);

done_testing();

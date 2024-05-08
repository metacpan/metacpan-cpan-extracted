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
	e => [qw/1 2 3/]
};

my $r = Rope->from_data($data);

is($r->{a}, 1);
is($r->{b}, 2);
is($r->{c}, 3);
is_deeply($r->{d}, { one => 1, two => 2, three => 3});
is_deeply($r->{e}, [qw/1 2 3/]);

$r = Rope->from_data($data, { use => ["Rope::Autoload"] });

is($r->a, 1);
is($r->b, 2);
is($r->c, 3);
is_deeply($r->d, { one => 1, two => 2, three => 3 });
is_deeply($r->e, [qw/1 2 3/]);

$r = Rope->from_data($data, { use => ["Rope::Monkey"] });

is($r->a, 1);
is($r->b, 2);
is($r->c, 3);
is_deeply($r->d, { one => 1, two => 2, three => 3 });
is_deeply($r->e, [qw/1 2 3/]);

ok(1);

done_testing();

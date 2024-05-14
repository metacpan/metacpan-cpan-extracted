use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new({a => 1, b => 2});

is($data->freeze->get('a'), 1);

eval {
	$data->set('a', 5);
};

like($@, qr/Modification of a read-only value attempted/);

is($data->unfreeze->get('a'), 1);

is($data->set('a', 5)->get('a'), 5);

done_testing();

use Test::More;

use Rope::Handles::Hash;

# clear
my $data = Rope::Handles::Hash->new(a => 1, b => 2, c => 3);
is($data->length, 3);
$data->clear;
is($data->length, 0);

# entries (alias for each)
$data = Rope::Handles::Hash->new(x => 10, y => 20);
my @entries = $data->entries(sub { "$_[0]=$_[1]" });
is_deeply([sort @entries], ['x=10', 'y=20']);

# values
$data = Rope::Handles::Hash->new(a => 3, b => 1, c => 2);
my @vals = $data->values;
is_deeply(\@vals, [1, 2, 3]);

# keys
my @keys = $data->keys;
is_deeply(\@keys, ['a', 'b', 'c']);

# set returns self for chaining
$data = Rope::Handles::Hash->new();
my $ret = $data->set('foo', 'bar');
is(ref $ret, 'Rope::Handles::Hash');
is($data->get('foo'), 'bar');

# delete returns self for chaining
$ret = $data->delete('foo');
is(ref $ret, 'Rope::Handles::Hash');
is($data->get('foo'), undef);

# assign multiple hashes
$data = Rope::Handles::Hash->new(a => 1);
$data->assign({ b => 2 }, { c => 3, d => 4 });
is($data->length, 4);
is($data->get('b'), 2);
is($data->get('c'), 3);
is($data->get('d'), 4);

# freeze and unfreeze
$data = Rope::Handles::Hash->new(a => 1);
$data->freeze;
eval { $data->{b} = 2 };
like($@, qr/restrict/i);
$data->unfreeze;
$data->{b} = 2;
is($data->get('b'), 2);

# new with hashref
$data = Rope::Handles::Hash->new({ foo => 'bar' });
is($data->get('foo'), 'bar');

done_testing();

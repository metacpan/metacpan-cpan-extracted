use Test::More;

use lib 't/ODS';

use Table::User;
use Table::Test;

my $user = Table::User->connect('File::JSON', {
	file => 't/filedb/users'
});

my $data = $user->all();

is(scalar @{$data}, 1);

my %row = %{ $data->[0] };

my $test = Table::Test->connect('File::JSON', {
	file => 't/filedb/test'
});

my $data2 = $test->all();

is($data2->[0]->username, 'lnation');

is($data2->first->username, 'lnation');
is($data2->last->username, 'lnation3');
while (my $data3 = $data2->next) {
	like($data3->username, qr/^lnation/);
}

while (my $data3 = $data2->prev) {
	like($data3->username, qr/^lnation/);
}

$data2->foreach(sub {
	my ($row) = @_;
});

my $hash = $data2->array_to_hash();

is_deeply($hash,  {
	'lnation' => {
		'username' => 'lnation',
		'last_name' => 'test',
		'first_name' => 'test'
	},
	'lnation2' => {
		'username' => 'lnation2',
		'last_name' => 'test2',
		'first_name' => 'test2'
	},
	'lnation3' => {
		'first_name' => 'test3',
		'last_name' => 'test3',
		'username' => 'lnation3'
	}
});

my $find = $data2->find(sub {
	$_[0]->{username} eq 'lnation2'
});

is_deeply($find, {
	'username' => 'lnation2',
	'last_name' => 'test2',
	'first_name' => 'test2'
});

my $find_index = $data2->find_index(sub {
	$_[0]->{username} eq 'lnation2'
});

is($find_index, 1);

my $reverse = $data2->reverse();

is($reverse->[0]->username, 'lnation3');

is($data2->table->rows->[0]->username, 'lnation3');

$data2->reverse();

my @records = $data->filter(sub { $_->{username} eq 'lnation' });

is (scalar @records, 1);
is ($records[0]->username, 'lnation');

my $one = $test->search(
	username => 'lnation2'
);

is(scalar @{ $one }, 1);

$test->create({
	username => 'xyzabc',
	first_name => 'xyz',
	last_name => 'abc',
});

is($test->table->rows->[-1]->username, 'xyzabc');

$test->update(
	username => 'xyzabc',
	{
		first_name => 'testing'
	}
);

is($test->table->rows->[-1]->first_name, 'testing');

$test->delete(
	username => 'xyzabc'
);

$test->create({
	username => 'xyzabc',
	first_name => 'testing',
	last_name => 'abc',
});


$find = $test->find(
	first_name => 'xyz',
	last_name => 'abc'
);

ok(!$find);

$find = $test->find(
	first_name => 'testing',
	last_name => 'abc'
);

my $success = $find->update(
	first_name => 'updated'
);

is($find->first_name, 'updated');

ok($find->first_name("other"));

is($find->first_name, 'other');

ok(my $success = $find->delete());

done_testing();

use Test::More;

use lib 't/ODS';

use Table::User;
use Table::Test;

my $user = Table::User->connect('Directory', {
	directory => 't/filedb/directory/truth/users',
	cache_directory => 't/filedb/directory/cache/users',
	serialize_class => 'YAML'
});

my $data = $user->all();

is(scalar @{$data}, 1);

my %row = %{ $data->[0] };

my $test = Table::Test->connect('Directory', {
	directory => 't/filedb/directory/truth/test',
	cache_directory => 't/filedb/directory/cache/test',
	serialize_class => 'YAML'
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

my $one = $test->search(
	username => 'lnation2'
);

is(scalar @{ $one }, 1);

my $stay_cached = $test->find(
	username => 'lnation2'
);

is($stay_cached->username, 'lnation2');

$test->create({
	username => "lnation4",
	first_name => "testing4",
	last_name => "testing4"
});

my $delete_cached = $test->find(
	username => 'lnation4'
);

is($delete_cached->username, 'lnation4');

$test->delete({
	username => "lnation4",
});


done_testing();

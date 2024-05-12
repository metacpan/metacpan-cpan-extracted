use Test::More;

use lib 't';

{
	package Odea;

	use Salus all => 1;

	header id => (
		label => 'ID',	
	);

	header firstName => (
		label => 'First Name',
	);

	header lastName => (
		label => 'Last Name',
	);

	header age => (
		label => 'Age',
	);

	1;
};

my $odea = Odea->new();

my $data = [1, 'Robert', 'Joseph', 32];

$odea->add_row($data);

is($odea->count, 1);

is_deeply($odea->rows->[0]->as_array, $data);

is($odea->get_row_col(0, 0)->value, 1);

is($odea->get_row_col(0, 1)->value, 'Robert');

ok($odea->get_row_col(0, 2)->value = 'Joshua');

is($odea->get_row_col(0, 2)->value, 'Joshua');

ok($odea->set_row_col(0, 2, 'Muse'));

is($odea->get_row_col(0, 2)->value, 'Muse');

ok($odea->delete_row(0));

is($odea->count, 0);

my $hash_data = {
	ID => 1, 
	firstName => 'Robert', 
	lastName => 'Joseph', 
	age => 32
};

$odea->add_row_hash($hash_data);

is($odea->count, 1);

is_deeply($odea->rows->[0]->as_array, $data);

is($odea->get_row_col(0, 0)->value, 1);

is($odea->get_row_col(0, 1)->value, 'Robert');

ok($odea->get_row_col(0, 2)->value = 'Joshua');

is($odea->get_row_col(0, 2)->value, 'Joshua');

ok($odea->set_row_col(0, 2, 'Muse'));

is($odea->get_row_col(0, 2)->value, 'Muse');

ok($odea->delete_row(0));

is($odea->count, 0);

done_testing();

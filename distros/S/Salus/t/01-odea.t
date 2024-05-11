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

my $odea = Odea->new(
	file => 't/test.csv'
);

$odea->file = 't/test.csv';


my $test_headers = [
	{
		index => 0,
		name => 'id',
		label => 'ID'
	},
	{
		index => 1,
		name => 'firstName',
		label => 'First Name'
	},
	{
		index => 2,
		name => 'lastName',
		label => 'Last Name'
	},
	{
		index => 3,
		name => 'age',
		label => 'Age'
	}
];

is_deeply($odea->headers, $test_headers);

is($odea->file, 't/test.csv');

is($odea->unprotected_read, 0);

$odea->read();

is(scalar @{$odea->rows}, 2);

$odea->write('t/test2.csv');

my $first_row = $odea->rows->[0]->as_array();

is_deeply($first_row, [1, 'Robert', 'Acock', 32]);

sub read_file {
	my ($file) = shift;
	open my $fh, '<', $file;
	my $data = do { local $/; <$fh> };
	close $fh;
	return $data;
}

my $file1 = read_file('t/test.csv');
my $file2 = read_file('t/test2.csv');
is($file1, $file2);

done_testing();

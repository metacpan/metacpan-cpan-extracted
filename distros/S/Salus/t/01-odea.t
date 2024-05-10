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

	header header => (
		label => 'Age',
	);

	1;
};

my $odea = Odea->new(
	file => 't/test.csv'
);

$odea->file = 't/test.csv';

$odea->read();

$odea->write('t/test2.csv');

ok(1);

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

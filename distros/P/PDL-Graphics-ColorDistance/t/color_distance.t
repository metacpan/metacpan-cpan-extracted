use strict;
use warnings;

use Test::More tests => 35;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Graphics::ColorDistance;
use FindBin;
use Data::Dumper;


my (@all_lab1, @all_lab2, @all_expected_delta_e);

my $test_data_fn = $FindBin::Bin . '/ciede2000testdata.txt';
open my $in, '<', $test_data_fn or die "Can't open $test_data_fn for reading: $!";
my $line_num = 0;
while (my $line = <$in>) {
	chomp $line;
	my @parts = split /\t/, $line;
	next unless @parts;

	push @all_lab1, [ @parts[0..2] ];
	push @all_lab2, [ @parts[3..5] ];
	push @all_expected_delta_e, $parts[6];

	my ($lab1, $lab2, $expected_delta_e) = (
		pdl([ @parts[0..2] ]),
		pdl([ @parts[3..5] ]),
		$parts[6]
	);
	my $delta_e = delta_e_2000($lab1, $lab2);
	ok abs($delta_e - $expected_delta_e) < 1e-4, "CIEDE2000 test data, line " . ++$line_num;
}
close $in;

{
	my ($lab1, $lab2, $expected_delta_e) = (
		pdl(@all_lab1),
		pdl(@all_lab2),
		pdl(@all_expected_delta_e)
	);

	my $delta_e = delta_e_2000($lab1, $lab2);

	my $diff = abs($delta_e - $expected_delta_e);
	ok $diff->max < 1e-4, "CIEDE2000 test data as one piddle";
}

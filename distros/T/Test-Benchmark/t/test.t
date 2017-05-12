use strict;
use warnings;

use Test::Tester;

use Test::More tests => 36;
use Test::NoWarnings;

use Test::Benchmark;

Test::Benchmark::builder(Test::Tester::capture());

my $fac30 = sub {fac(30)};
my $fac20 = sub {fac(20)};
my $fac10 = sub {fac(10)};

check_test(
	sub {
		is_fastest("fac10", -1,
			{
				fac10 => $fac10,
				fac20 => $fac20,
				fac30 => $fac30,
			},
			"fac10 fastest",
		);
	},
	{
		actual_ok => 1,
		diag => "",
		name => "fac10 fastest",
	},
	"fac10 fastest"
);

check_test(
	sub {
		is_fastest("fac30", -1,
			{
				fac10 => $fac10,
				fac20 => $fac20,
				fac30 => $fac30,
			},
			"fac30 fastest",
		);
	},
	{
		actual_ok => 0,
	},
	"fac30 not fastest"
);

check_tests(
	sub {
		is_faster(-1, $fac10, $fac20, "10 faster than 20 time");
		is_faster(1000, $fac10, $fac20, "10 faster than 20 num");
	},
	[
		{
			actual_ok => 1,
			diag => "",
			name => "10 faster than 20 time",
		},
		{
			actual_ok => 1,
			diag => "",
			name => "10 faster than 20 num",
		},
	],
	"10 faster than 20"
);

check_tests(
	sub {
		is_faster(-1, $fac20, $fac10, "20 faster than 10 time");
		is_faster(1000, $fac20, $fac10, "20 faster than 10 num");
	},
	[
		{
			actual_ok => 0,
		},
		{
			actual_ok => 0,
		},
	],
	"20 slower than 10"
);

check_test(
	sub {
		is_faster(-1, 2, $fac10, $fac30, "30 2 times faster than 10");
	},
	{
		actual_ok => 0,
	},
	"30 2 times than 10"
);

sub fac
{
	my $x = shift;
	return 1 if $x <= 1;
	return $x * fac($x-1);
}

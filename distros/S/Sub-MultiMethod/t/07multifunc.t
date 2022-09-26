use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Local;
	use Types::Standard -types;
	use Sub::MultiMethod 'multifunction';
	
	multifunction sum => (
		positional => [ Num, Num ],
		code       => sub {
			my ($x, $y) = @_;
			$x + $y;
		},
	);
	
	multifunction sum => (
		positional => [ ArrayRef ],
		code       => sub {
			my ($arr) = @_;
			my $sum = 0;
			$sum += $_ for @$arr;
			$sum;
		},
	);
}

is(Local::sum(2, 3), 5);
is(Local::sum([1..4]), 10);

{
	package Local2;
	use Types::Standard -types;
	use Sub::MultiMethod 'multimethod';
	
	multimethod sum => (
		method     => 2,
		positional => [ Num, Num ],
		code       => sub {
			my ($self, $context, $x, $y) = @_;
			$x + $y;
		},
	);
	
	multimethod sum => (
		method     => 2,
		positional => [ ArrayRef ],
		code       => sub {
			my ($self, $context, $arr) = @_;
			my $sum = 0;
			$sum += $_ for @$arr;
			$sum;
		},
	);
}

my $ctx = {};
is(Local2->sum($ctx, 2, 3), 5);
is(Local2->sum($ctx, [1..4]), 10);

done_testing;

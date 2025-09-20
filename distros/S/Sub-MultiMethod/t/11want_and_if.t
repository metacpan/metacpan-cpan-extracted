use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Local::Want;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	multifunction xxx => (
		want   => SCALAR,
		code   => sub { 1 },
	);
	
	multifunction xxx => (
		code   => sub { 2 },
	);
}

is_deeply( [ scalar Local::Want::xxx() ], [1] );
is_deeply( [        Local::Want::xxx() ], [2] );

{
	package Local::If;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	my $first = 0;
	
	multifunction xxx => (
		if     => sub { !$first++ },
		code   => sub { 1 },
	);
	
	multifunction xxx => (
		code   => sub { 2 },
	);
}

is_deeply( Local::If::xxx(), 1 );
is_deeply( Local::If::xxx(), 2 );
is_deeply( Local::If::xxx(), 2 );

done_testing;

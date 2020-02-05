use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $e;
{
	package Local::Calculator;
	use Class::Tiny;
	use Types::Standard qw( Int Num );
	use Sub::MultiMethod qw( monomethod );
	
	monomethod add => (
		signature => [ Int, Int ],
		code      => sub { my ($self, $x, $y) = (shift, @_); $x + $y },
	);
	
	$e = ::exception {
		monomethod add => (
			signature => [ Num, Num ],
			code      => sub { my ($self, $x, $y) = (shift, @_); $x + $y },
		);
	};
}

like($e, qr/Monomethod conflicts with existing method/);

my $obj = Local::Calculator->new;

is( $obj->add(4, 5), 9 );
is( $obj->add(4, -1), 3 );

isnt(
	exception { $obj->add(4, 1.1) },
	undef,
);

my $e2 = exception {
	package Local::Calculator;
	use Types::Standard qw( ArrayRef Int );
	use Sub::MultiMethod qw( multimethod );
	
	multimethod add => (
		signature => [ ArrayRef[Int] ],
		code      => sub {
			my ($self, $arr) = (shift, @_);
			my $sum = 0;
			$sum += $_ for @$arr;
			return $sum;
		},
	);
};

like($e2, qr/Multimethod conflicts with monomethod/);

is( $obj->add(4, 5), 9 );

done_testing;

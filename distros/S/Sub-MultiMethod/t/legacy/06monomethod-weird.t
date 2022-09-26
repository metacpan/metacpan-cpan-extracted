use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $e;
{
	package Local::Calculator;
	use Class::Tiny;
	use Types::Standard qw( Int Num );
	use Sub::MultiMethod qw( multimethod );
	
	# monomethod is really just multimethod(undef)+alias
	# but with a nicer error message for conflicts
	multimethod undef, => (
		alias     => 'add',
		signature => [ Int, Int ],
		code      => sub { my ($self, $x, $y) = (shift, @_); $x + $y },
	);
	
	$e = ::exception {
		multimethod undef, => (
			alias     => 'add',
			signature => [ Num, Num ],
			code      => sub { my ($self, $x, $y) = (shift, @_); $x + $y },
		);
	};
}

like($e, qr/Alias conflicts with existing method/);

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

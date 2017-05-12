use Test::More;
BEGIN { 
	eval "use MooseX::Types::Moose; 1"
		or plan skip_all => "need MooseX::Types::Moose for this test";
	
	plan tests => 1;
};

use MooseX::DeclareX
	types => [
		-Moose => [qw(Str Num)],
	];

try {
	class X {
		has n => (is => read_only, isa => Num);
	}
	X->new(n => "Hello");
}

catch ($e) {
	like $e, qr{Attribute \(n\) does not pass .* for 'Num' with value "Hello"};
}

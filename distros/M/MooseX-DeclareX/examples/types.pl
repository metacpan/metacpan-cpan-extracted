use 5.010;
use MooseX::DeclareX
	types => [
		-Moose => [-all],
		-URI,		
	];

class Foo
{
	say ArrayRef[ Str ];
}



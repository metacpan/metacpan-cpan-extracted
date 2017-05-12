use strict;
use warnings;
use Test::More tests => 4;

my $XXX;

{
	package XXX;
	
	use Moose;
	use Moose::Util::TypeConstraints;
	use MooseX::CustomInitArgs qw( before_typecheck after_typecheck );
	
	subtype 'MyArrayRef', as 'ArrayRef';
	coerce 'MyArrayRef', from 'Any', via { [$_] };
	
	has xxx => (
		is        => 'ro',
		isa       => 'MyArrayRef',
		coerce    => 1,
		init_args => [
			_xxx => after_typecheck { $XXX = $_ },
			xxx_ => before_typecheck { $XXX = $_ },
		],
	);
}

for my $i (666 .. 667)
{
	XXX->new( _xxx => $i );
	
	is_deeply(
		$XXX,
		[ $i ],
		'coercion happens before init_args coderefs get called',
	);
	
	XXX->new( xxx_ => $i );
	
	is_deeply(
		$XXX,
		$i,
		'coercion happens after init_args coderefs get called',
	);
	
	XXX->meta->make_immutable;
}

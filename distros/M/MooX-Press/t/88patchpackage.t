use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Zydeco::Lite;

my $lex = 1;

my $app = app sub {
	role 'Patcher' => sub {
		after_apply {
			has 'xyzzy';
			
			method 'mymethod'
			=> [ 'Str' ]
			=> sub { 42 };
			
			multi_method 'blep'
			=> [ 'HashRef' ]
			=> sub { '{}' };
			
			multi_method 'blep'
			=> [ 'ArrayRef' ]
			=> sub { '[]' };
			
			constant XYZ => 666;
			
			around 'xxx' => sub {
				my ( $next, $self ) = ( shift, shift );
				$self->$next() / 2;
			};
			before [ 'xxx' ] => sub { ++$lex }; 
		};
	};
	class 'Thingy' => ( with => 'Patcher' ) => sub {
		multi_method 'blep'
		=> [ 'Str' ]
		=> sub { '""' };
		
		method 'xxx' => sub { 84 };
	};
};

my $obj = $app->new_thingy( 'xyzzy' => 999 );

is(
	$obj->xyzzy,
	999,
	'attribute installed',
);

is(
	$obj->mymethod(''),
	42,
	'method installed',
);

isnt(
	exception { $obj->mymethod() },
	undef,
	'signature works',
);

is(
	$obj->blep({}),
	'{}',
	'multimethod candidate 1',
);

is(
	$obj->blep([]),
	'[]',
	'multimethod candidate 2',
);

is(
	$obj->blep(""),
	'""',
	'multimethod candidate 3',
);

isnt(
	exception { $obj->blep(undef) },
	undef,
	'multimethod exception',
);

is(
	$obj->XYZ,
	666,
	'constant',
);

is(
	$lex,
	1,
	"before modifier hasn't fired yet"
);

is(
	$obj->xxx,
	42,
	'around modifier',
);

is(
	$lex,
	2,
	"before modifier"
);


done_testing;

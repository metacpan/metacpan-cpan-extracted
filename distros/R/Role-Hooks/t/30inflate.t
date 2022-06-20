use strict;
use warnings;
use Test::More;

{ package Local::Dummy1; use Test::Requires 'Moo'; };

my @got;

{
	package Local::MyClass;
	use Moo;
	
	'Role::Hooks'->after_inflate( __PACKAGE__, sub {
		push @got, "Classy!";
	} );
}

{
	package Local::MyRole1;
	use Moo::Role;
	use Role::Hooks;
	
	'Role::Hooks'->after_inflate( __PACKAGE__, sub {
		push @got, @_;
	} );
}

{
	package Local::MyRole2;
	use Moo::Role;
	with 'Local::MyRole1';
}

is_deeply(
	[ sort @got ],
	[],
	'Nothing so far',
);

if ( eval 'package XYZ; use Moose; with "Local::MyRole2"; 1' ) {
	is_deeply(
		[ sort @got ],
		[ 'Local::MyRole1', 'Local::MyRole2' ],
		'Both packages listed',
	) or diag explain( \@got );
	
	Local::MyClass->meta->name;
	
	is_deeply(
		[ sort @got ],
		[ 'Classy!', 'Local::MyRole1', 'Local::MyRole2' ],
		'Three packages listed',
	) or diag explain( \@got );
}
else {
	note "Skipped inflation test as Moose wouldn't load";
}

done_testing;

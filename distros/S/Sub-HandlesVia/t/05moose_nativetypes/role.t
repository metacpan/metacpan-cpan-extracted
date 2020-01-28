use strict;
use warnings;
use Test::More;
use Test::Fatal;
{ package Local::Dummy1; use Test::Requires 'Moose' };

{
	package Local::Role1;
	use Moose::Role;
	use Sub::HandlesVia;
	has nums => (
		is           => 'ro',
		isa          => 'ArrayRef[Int]',
		builder      => '_build_nums',
		handles_via  => 'Array',
		handles      => { pop_num => 'pop', push_num => 'push' },
	);
	sub _build_nums { [ 1..10 ] }
}

{
	package Local::Class1;
	use Moose;
	with 'Local::Role1';
}

#require B::Deparse;
#::note( B::Deparse->new->coderef2text(\&Local::Class1::pop_num) );

my $obj = Local::Class1->new;

is( $obj->pop_num, 10 );
is( $obj->pop_num, 9 );
is( $obj->pop_num, 8 );
is( $obj->pop_num, 7 );

isnt(
	exception { $obj->push_num(44.5) },
	undef,
);

is( $obj->pop_num, 6 );

is(
	exception { $obj->push_num(6) },
	undef,
);

is( $obj->pop_num, 6 );

done_testing;

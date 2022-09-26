use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Local::Class1;
	use Class::Tiny;
	use Types::Standard -types;
	use Sub::MultiMethod qw(multimethod);
	
	multimethod foo => (
		positional => [ HashRef ],
		code       => sub { 'Class1:foo:HashRef' },
		alias      => 'foolish',
	);
	
	multimethod foo => (
		positional => [ ArrayRef ],
		code       => sub { 'Class1:foo:ArrayRef' },
	);
	
	multimethod bar => (
		positional => [ HashRef ],
		code       => sub { 'Class1:bar:HashRef' },
	);
}

my $obj1 = Local::Class1->new;

is( $obj1->foo({}), 'Class1:foo:HashRef' );
is( $obj1->foo([]), 'Class1:foo:ArrayRef' );
is( $obj1->bar({}), 'Class1:bar:HashRef' );
isnt(
	exception { $obj1->bar() },
	undef,
);

is( $obj1->foolish({}), 'Class1:foo:HashRef' );
isnt(
	exception { $obj1->foolish() },
	'using an alias does not bypass signature'
);

{
	package Local::Class2;
	use Class::Tiny;
	our @ISA = qw(Local::Class1);
	use Types::Standard -types;
	use Sub::MultiMethod qw(multimethod);
	
	multimethod foo => (
		positional => [ HashRef->where(sub{1})->where(sub{2})->where(sub{3}) ],
		code       => sub { 'Class2:foo:HashRef+3' },
	);
	
	# mono method
	sub bar {
		'Class2:bar';
	}
}

my $obj2 = Local::Class2->new;

is( $obj2->foo({}), 'Class2:foo:HashRef+3' );
is( $obj2->foo([]), 'Class1:foo:ArrayRef', 'candidate from grandparent class' );
is( $obj2->bar({}), 'Class2:bar', 'monomethod overriding inherited multimethod' );
is( $obj2->bar(), 'Class2:bar', 'monomethod overriding inherited multimethod' );

{
	package Local::Class3;
	use Class::Tiny;
	our @ISA = qw(Local::Class2);
	use Types::Standard -types;
	use Sub::MultiMethod qw(multimethod);
	
	multimethod foo => (
		positional => [ HashRef ],
		code       => sub { 'Class3:foo:HashRef' },
	);
	
	multimethod foo => (
		positional => [ Int ],
		code       => sub { 'Class3:foo:Int' },
	);

	multimethod bar => (
		positional => [ Int ],
		code       => sub { 'Class3:bar:Int' },
	);
	
	multimethod bar => (
		positional => [ RegexpRef ],
		code       => sub { 'Class3:bar:RegexpRef' },
	);
}


my $obj3 = Local::Class3->new;

is( $obj3->foo({}), 'Class2:foo:HashRef+3', 'more constrained candidate in parent class' );
is( $obj3->foo([]), 'Class1:foo:ArrayRef', 'candidate from grandparent class' );
is( $obj3->foo(42), 'Class3:foo:Int' );
is( $obj3->bar(42), 'Class3:bar:Int' );
is( $obj3->bar(qr//), 'Class3:bar:RegexpRef' );
is( $obj3->bar(), 'Class2:bar', 'inherited monomethod being used as last resort' );
is( $obj3->bar({}), 'Class2:bar', 'even higher up candidates are hidden by inherited monomethod' );


{
	package Local::Class4;
	use Class::Tiny;
	our @ISA = qw(Local::Class3);
	use Types::Standard -types;
	use Sub::MultiMethod qw(multimethod);

	multimethod foo => (
		positional => [ Num ],
		code       => sub { 'Class4:foo:Num' },
	);
	multimethod foo => (
		positional => [ Num ],
		code       => sub { 'Class4:foo:Num(again)' },
	);
}

my $obj4 = Local::Class4->new;

is( $obj4->foo({}), 'Class2:foo:HashRef+3', 'more constrained candidate in grandparent class' );
is( $obj4->foo([]), 'Class1:foo:ArrayRef', 'candidate from greatgrandparent class' );
is( $obj4->foo(42), 'Class3:foo:Int' );
is( $obj4->bar(42), 'Class3:bar:Int' );
is( $obj4->bar(qr//), 'Class3:bar:RegexpRef' );
is( $obj4->bar(), 'Class2:bar', 'inherited monomethod being used as last resort' );
is( $obj4->bar({}), 'Class2:bar', 'even higher up candidates are hidden by inherited monomethod' );
is( $obj4->foo(4.2), 'Class4:foo:Num', 'earlier definition wins' );

is( $obj4->foolish({}), 'Class1:foo:HashRef' );
isnt(
	exception { $obj4->foolish() },
	'using an alias does not bypass signature'
);

done_testing;

use Test::More tests => 5;

{
	package Foo;
	use MooseX::ArrayRef; 
	has [qw/a c e/] => (is => 'ro');
}

{
	package Bar;
	use Moose::Role;
	has [qw/b/] => (is => 'ro');
}

{
	package Foo::Bar;
	use MooseX::ArrayRef; extends 'Foo'; with 'Bar';
	has [qw/d/] => (is => 'ro');
}

ok defined( Foo::Bar->meta->slot_index($_) ) for 'a'..'e';

note
	q(slot_to_index_map ),
	explain(Foo::Bar->meta->slot_to_index_map);
	

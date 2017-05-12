package Foo;

BEGIN{
	use Object::AutoAccessor;
	push @ISA, 'Object::AutoAccessor';
}

1;

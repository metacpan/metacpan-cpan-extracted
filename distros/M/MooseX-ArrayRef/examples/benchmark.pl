use Benchmark qw(:all);

{
	package Local::Foo;
	use Moose::Role;
	has foo => (is => 'rw');
	sub test {
		my $class = shift;
		my $self  = $class->new;
		$self->foo($_) for 0 .. 99;
	}
}

{
	package Local::HashRef::M;
	use Moose;
	with 'Local::Foo';
}

{
	package Local::HashRef::I;
	use Moose;
	with 'Local::Foo';
	__PACKAGE__->meta->make_immutable;
}

{
	package Local::ArrayRef::M;
	use MooseX::ArrayRef;
	with 'Local::Foo';
}

{
	package Local::ArrayRef::I;
	use MooseX::ArrayRef;
	with 'Local::Foo';
	__PACKAGE__->meta->make_immutable;
}

cmpthese(10_000, {
	HashRef_M => sub { Local::HashRef::M::->test },
	HashRef_I => sub { Local::HashRef::I::->test },
	ArrayRef_M => sub { Local::ArrayRef::M::->test },
	ArrayRef_I => sub { Local::ArrayRef::I::->test },
});

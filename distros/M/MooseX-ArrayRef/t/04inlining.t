use Test::More tests => 4;

{
	package Local::Foo;
	use MooseX::ArrayRef;
	has foo => (is => 'rw', clearer => 'clear_foo', predicate => 'has_foo');
	__PACKAGE__->meta->make_immutable;
}

my $obj = Local::Foo->new(foo => 1);
ok($obj->has_foo);

$obj->clear_foo;
ok not($obj->has_foo);
is($obj->foo, undef);

$obj->foo(2);
ok($obj->has_foo);

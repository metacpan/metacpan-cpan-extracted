
my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'bar');
can_ok($foo, 'baz');


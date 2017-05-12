
my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

can_ok($bar, 'bar');
can_ok($bar, 'baz');
can_ok($bar, 'foo');


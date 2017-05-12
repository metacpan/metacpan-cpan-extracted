my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'bar');
can_ok($foo, 'baz');

if ($foo->can('_is_postprocessed')) {
    is($foo->is_postprocessed, 1);
}
else {
    is($foo->is_postprocessed, 0);
}


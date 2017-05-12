use Test::More tests => 29;

BEGIN { use_ok('Symbol::Opaque') }

defsym('foo'); 
defsym('bar'); 

{
    ok(foo(my $x) << foo(10), "binding succeeded");
    is($x, 10, "simple");
}

{
    ok(!( foo(my $x) << 42 ), "binding failed");
}

{
    ok(foo(my $x, bar(my $y)) << foo(1, bar(2)), "binding succeeded");
    is($x, 1, "x binding");
    is($y, 2, "y binding");
} 

{
    ok(foo(1, bar(2)) << foo(1, bar(2)), "trivial constant binding");
}

{
    ok(!( foo(my $x, 2) << foo(2, 3) ), "binding failed");
    ok(!defined $x, "x not bound even after partial success");
}

{
    my $x = "hello";
    ok(!( foo($x) << foo(42) ), "binding fails on already-defined variables");
    is($x, "hello", "x is preserved");
}

{
    my $x;
    ok(foo($x, $x) << foo(3, 3), "binding succeeds on nonlinear queries");
    is($x, 3, "and it bound correctly");
}

{
    my $x;
    ok(!( foo($x, $x) << foo(3, 4) ), "binding fails on nonlinear queries");
    ok(!defined $x, "and x didn't get bound");
}

{
    my $x;
    ok(foo($x, bar($x)) << foo(foo(3), bar(foo(3))), "a more complex nonlinear query");
    ok(foo(my $y) << $x, "the correct thing matched");
    is($y, 3, "even");
}

{
    my $x;
    ok(!( foo($x, bar($x)) << foo(foo(3), bar(3)) ), "a more complex nonlinear failing query");
    ok(!defined $x, "x not bound");
}

{
    my $x;
    ok(foo([1, free $x, _]) << foo([1,2,3]), "array matching");
    is($x, 2, "x bound");
}

{
    my $x;
    ok(!(foo([1, free $x, ]) << foo([2,3,4])), "array nonmatching");
    ok(!defined $x, "x not bound");
}

{
    my $x;
    ok(foo({ a => free $x }) << foo({ a => 1, b => 2 }), "hash matching");
    is($x, 1, "x bound");
}

{
    my $x;
    ok(!(foo({ a=> free $x }) << foo({ b => 1 })), "hash nonmatching");
    ok(!defined $x, "x not bound");
}

# vim: ft=perl :

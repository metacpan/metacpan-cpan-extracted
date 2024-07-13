package Foo;

use Sub::Private;

sub foo {
    return 42;
}

sub bar :Private {
    return foo() + 1;
}

sub baz {
    return bar() + 1;
}

1;

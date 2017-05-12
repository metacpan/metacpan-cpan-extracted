package One;

sub new {
    return bless {}, shift;
}

sub foo {
    return "foo";
}
sub bar {
    return "bar";
}
sub baz {
    return "baz";
}
1;

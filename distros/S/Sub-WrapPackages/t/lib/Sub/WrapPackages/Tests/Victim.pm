package Sub::WrapPackages::Tests::Victim;

sub foo {
    return (2, bar(1));
}

sub bar {
    baz('OMG', 'ROBOTS', $_[0] + 4);
}

sub baz {
    return @_;
}

1;

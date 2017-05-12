sub trace {
    my ($maker, $target, $deps, $matches) = @_;
    push @OUTPUT, "Building $target with matches: @{$matches}\n";
}

1;

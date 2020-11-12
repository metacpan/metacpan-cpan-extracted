sub foo {
    my ($x) = @_;

    $x or return;
    return $x + 1;
}

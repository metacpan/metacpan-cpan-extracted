sub foo {
    my ($x, $y) = @_;

    $x or return;
    $y or return;
    return $x + $y;
}

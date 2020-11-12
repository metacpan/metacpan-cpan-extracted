sub foo {
    my ($x, $y) = @_;
    return unless $x;
    return unless $y;
    return $x + $y;
}

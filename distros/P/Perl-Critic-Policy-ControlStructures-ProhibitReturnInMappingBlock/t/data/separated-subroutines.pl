use strict;
use warnings;

sub calc_y {
    my ($x) = @_;
    return 2 if $x < 10;
    return 3 if $x < 100;
    return 4;
}

sub foo {
    my ($x) = @_;
    my $y = calc_y($x);
    return $x * $y;
}

print foo(5);

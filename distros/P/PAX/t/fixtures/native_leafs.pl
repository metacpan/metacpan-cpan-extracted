use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

sub subtract {
    my ($left, $right) = @_;
    return $left - $right;
}

sub multiply {
    my ($left, $right) = @_;
    return $left * $right;
}

sub greater_than {
    my ($left, $right) = @_;
    return $left > $right;
}

die "bad add" unless add(2, 3) == 5;
die "bad subtract" unless subtract(10, 3) == 7;
die "bad multiply" unless multiply(6, 7) == 42;
die "bad greater_than" unless greater_than(10, 3) == 1;
1;

=pod

=head1 NAME

t/fixtures/native_leafs.pl - fixture for fixture with small native-shaped leaf routines

=head1 DESCRIPTION

This fixture exists to provide fixture with small native-shaped leaf routines. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut

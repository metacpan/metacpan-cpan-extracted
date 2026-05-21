use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

our $MUTATED = 0;

sub mutate_symbols {
    no strict 'refs';
    *dynamic_symbol = sub { return 1 };
    $MUTATED = 1;
    return $MUTATED;
}

die "bad add" unless add(2, 3) == 5;
1;

=pod

=head1 NAME

t/fixtures/mutation.pl - fixture for fixture that mutates state across runtime operations

=head1 DESCRIPTION

This fixture exists to provide fixture that mutates state across runtime operations. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut

use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

my $value = add(2, 3);
die "bad arithmetic" unless $value == 5;
1;

=pod

=head1 NAME

t/fixtures/simple.pl - fixture for minimal standalone fixture for smoke coverage

=head1 DESCRIPTION

This fixture exists to provide minimal standalone fixture for smoke coverage. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut

use strict;
use warnings;

sub sum_even_to_n {
    my ($n) = @_;
    my $sum = 0;
    for (my $i = 0; $i <= $n; $i += 2) {
        $sum += $i;
    }
    return $sum;
}

die "bad sum_even_to_n" unless sum_even_to_n(10) == 30;
1;

=pod

=head1 NAME

t/fixtures/unsupported_loop.pl - fixture for fixture that represents a loop shape the native path should decline

=head1 DESCRIPTION

This fixture exists to provide fixture that represents a loop shape the native path should decline. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut

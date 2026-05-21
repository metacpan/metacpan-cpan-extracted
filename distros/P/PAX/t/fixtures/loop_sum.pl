use strict;
use warnings;

sub sum_to_n {
    my ($n) = @_;
    my $sum = 0;
    for (my $i = 1; $i <= $n; $i++) {
        $sum += $i;
    }
    return $sum;
}

die "bad sum_to_n" unless sum_to_n(10) == 55;
1;

=pod

=head1 NAME

t/fixtures/loop_sum.pl - fixture for fixture with a simple hot loop used by acceleration tests

=head1 DESCRIPTION

This fixture exists to provide fixture with a simple hot loop used by acceleration tests. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut

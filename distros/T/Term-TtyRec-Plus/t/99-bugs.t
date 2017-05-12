use Test::More tests => 1;
use Term::TtyRec::Plus;

# check whether two floating point values are close enough
sub is_float {
    my ($a, $b, $test) = @_;
    if (abs($a - $b) < 1e-4) {
        pass($test);
    }
    else {
        fail($test);
        diag("Expected $a to be close to $b.");
    }
}

################################################################################
# 1. time_threshold did not work correctly

my $t = Term::TtyRec::Plus->new(
    infile         => "t/nethack.ttyrec",
    time_threshold => .01,
);
my $time = 0;
while (my $frame_ref = $t->next_frame) {
    $time += $frame_ref->{diff};
}
is_float($time, 9.93914103507996, "time_threshold fix");

################################################################################

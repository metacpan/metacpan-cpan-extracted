use Test::More tests => 7;
use Term::TtyRec::Plus;

# "constants"
my $ttyrec = "t/nethack.ttyrec";
my $frames = 1783;
my $time = 434.991698026657;

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

my $callback_called = 0;

sub filter {
    my ($data_ref, $time_ref, $prev_ref) = @_;
    ++$callback_called;
    $$time_ref = $$prev_ref + ($$time_ref - $$prev_ref) / 2
        if defined $$prev_ref;
    $$data_ref =~ s/Eidolos/Stumbly/ig;
}

my $t = Term::TtyRec::Plus->new(
    infile => $ttyrec,
    frame_filter => \&filter,
);

is($t->frame_filter(), \&filter, "frame_filter set properly");

my $diffs_full = 0;
my $diffs = 0;
my $relative_time = 0;
my $eidolos = 0;

while (my $frame_ref = $t->next_frame()) {
    $diffs_full += $frame_ref->{diffed_timestamp} - $frame_ref->{prev_timestamp}
        if $frame_ref->{frame} > 1;

    $diffs += $frame_ref->{diff};
    $relative_time = $frame_ref->{relative_time};

    $eidolos += $frame_ref->{data} =~ /Eidolos/i;
}

is($callback_called, $frames, "Callback called once per frame.");
is_float($diffs_full, $time, "Sum of all time differences pre-filter equals the ttyrec's total time");
is_float($diffs, $time / 2, "Sum of all time differences equals the ttyrec's total time halved");
is_float($relative_time, $time / 2, "Relative time of last frame equals the ttyrec's total time halved");

is_float($t->accum_diff(), -1 * ($time - $diffs), "t->accum_diff() reports the loss of half the total time");
is($eidolos, 0, "No appearances of string 'Eidolos', which was filtered out.");


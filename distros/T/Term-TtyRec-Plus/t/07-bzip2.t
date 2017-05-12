use Test::More tests =>   10 # initial sanity checks
                        + 5  # number of frames
                        * 11 # tests per frame
                        + 1  # post-read tests
                        ;

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

my $t = Term::TtyRec::Plus->new(
    infile => "t/simple.ttyrec.bz2",
);
isnt($t, undef, "new returns something");
can_ok($t, qw(next_frame infile filehandle time_threshold frame_filter frame prev_timestamp relative_time accum_diff));

# initial settings
is($t->infile(), "t/simple.ttyrec.bz2", "t->infile() set correctly");
isnt($t->filehandle(), undef, "t->filehandle() defined");
is($t->time_threshold(), undef, "t->time_threshold() initially undef");
isnt($t->frame_filter(), undef, "t->frame_filter() defined");
is($t->frame(), 0, "t->frame() initially 0");
is($t->prev_timestamp(), undef, "t->prev_timestamp() initially undef");
is($t->relative_time(), 0, "t->relative_time() initially 0");
is($t->accum_diff(), 0, "t->accum_diff() initially 0");

my @expected_outputs = (
    [undef,               undef], # for ease with frame_number, etc.
    ["frame 1",           1166173605.32873],
    ["frame 2",           1166173605.90382],
    ["frame 3",           1166173606.20291],
    ["penultimate frame", 1166173606.83821],
    ["final frame",       1166173608.21921],
);
my $frame_number = 0;
my $relative_time = 0;

while (my $frame_ref = $t->next_frame) {
    ++$frame_number;
    my @frame = @{ $expected_outputs[$frame_number] };

    is($frame_ref->{frame}, $frame_number, "Frame number ($frame_number) correct (from frame_ref)");
    is($frame_ref->{frame}, $frame_number, "Frame number ($frame_number) correct (from t->frame())");
    is($frame_ref->{data}, $frame[0], "Frame $frame_number data block is correct");

    is_float($frame_ref->{orig_timestamp}, $frame[1], "Frame $frame_number orig_timestamp is correct");
    is_float($frame_ref->{diffed_timestamp}, $frame[1], "Frame $frame_number diffed_timestamp is correct");
    is_float($frame_ref->{timestamp}, $frame[1], "Frame $frame_number timestamp is correct");
    is_float($t->prev_timestamp(), $frame[1], "Frame $frame_number timestamp is correct (from t->prev_timestamp())");

    if ($frame_number == 1) {
        is($frame_ref->{prev_timestamp}, undef, "Frame $frame_number prev_timestamp is correct (from frame_ref)");
        is($frame_ref->{diff}, 0, "Frame $frame_number diff is correct");
    }
    else {
        is_float($frame_ref->{prev_timestamp}, $expected_outputs[$frame_number - 1][1], "Frame $frame_number prev_timestamp is correct");
        is_float($frame_ref->{diff}, $frame[1] - $expected_outputs[$frame_number - 1][1], "Frame $frame_number diff is correct");
    }

    $relative_time += $frame_number == 1 ? 0 : $frame_ref->{diff};
    is_float($frame_ref->{relative_time}, $relative_time, "Frame $frame_number relative time (from frame_ref)");
    is_float($t->relative_time(), $relative_time, "Frame $frame_number relative time (from t->relative_time())");
}

is($t->next_frame, undef, "next_frame returns undef after EOF");


use Test::More tests =>   2  # initial states
                        * 5; # tests per initial state
use Term::TtyRec::Plus;

sub halve_time {
    my ($data_ref, $time_ref, $prev_ref) = @_;
    $$time_ref = $$prev_ref + ($$time_ref - $$prev_ref) / 2
        if defined $$prev_ref;
}

foreach my $initial_state (
    {
        frame          => 0,
        accum_diff     => 0,
        prev_timestamp => undef,
        relative_time  => 0,
    },

    {
        frame          => 1101,
        accum_diff     => -.3333,
        prev_timestamp => 1032981,
        relative_time  => 1923,
    },
)
{
    my $t = Term::TtyRec::Plus->new(
        infile       => "t/nethack.ttyrec",
        frame_filter => \&halve_time,
        %$initial_state,
    );
    my $frame_ref;

    my $first_frame_ref = $t->next_frame();

    while ($frame_ref = $t->next_frame()) {
        last if $frame_ref->{frame} == 100;
    }

    $t->rewind();

    is($t->frame(), $initial_state->{frame}, "rewind() resets frame counter");
    is($t->relative_time(), $initial_state->{relative_time}, "rewind() resets relative_time");
    is($t->accum_diff(), $initial_state->{accum_diff}, "rewind() resets accum_diff");
    is($t->prev_timestamp(), $initial_state->{prev_timestamp}, "rewind() resets prev_timestamp");

    $frame_ref = $t->next_frame();

    my $ok = 1;
    while (my ($k, $v) = each(%{$first_frame_ref})) {
        if (!defined($v)) {
            exists($frame_ref->{$k}) && !defined($frame_ref->{$k}) or $ok = 0;
        }
        else {
            $frame_ref->{$k} eq $v or $ok = 0;
        }
    }

    ok($ok, "All the frame_ref fields are set properly after a rewind()");
}


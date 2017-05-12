use Test::More tests => 12;
use Term::TtyRec::Plus;

my $frames_read;

# test missing file ############################################################

$frames_read = 0;

eval {
    my $t = Term::TtyRec::Plus->new(
        infile => "t/missing.ttyrec",
    );
    my $time = 0;
    while (my $frame_ref = $t->next_frame()) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 0, "exactly zero (well-formed) frames read");
like($@, qr/Unable to open 't\/missing\.ttyrec' for reading/, "\$@ contains the correct error");

# test negative time_threshold #################################################

$frames_read = 0;

eval {
    my $t = Term::TtyRec::Plus->new(
        infile         => "t/simple.ttyrec",
        time_threshold => -1,
    );
    my $time = 0;

    while (my $frame_ref = $t->next_frame()) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 0, "no frames read");
like($@, qr/Cannot have a negative time threshold/, "\$@ contains the correct error");

# test malformed ttyrec (header) ###############################################

$frames_read = 0;

eval {
    my $t = Term::TtyRec::Plus->new(
        infile => "t/malformed-header.ttyrec",
    );
    my $time = 0;

    while (my $frame_ref = $t->next_frame()) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 3, "exactly three (well-formed) frames read");
like($@, qr/Expected 12-byte header, got \d+ /, "\$@ contains the correct error");

# test malformed ttyrec (data) #################################################

$frames_read = 0;

eval {
    my $t = Term::TtyRec::Plus->new(
        infile => "t/malformed-data.ttyrec",
    );
    my $time = 0;

    while (my $frame_ref = $t->next_frame()) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 1, "exactly one (well-formed) frame read");
like($@, qr/Expected 19-byte frame, got \d+ /, "\$@ contains the correct error");

# test filtering timestamp to -1 ###############################################

$frames_read = 0;

eval {
    sub bad_callback {
        my ($data, $time, $prev) = @_;
        $$time = -1;
    }

    my $t = Term::TtyRec::Plus->new(
        infile       => "t/simple.ttyrec",
        frame_filter => \&bad_callback,
    );
    my $time = 0;

    while (my $frame_ref = $t->next_frame()) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 0, "no frames read");
like($@, qr/Unable to create a new header, \w+ portion of timestamp/, "\$@ contains the correct error");

# test bad grep() arg ##########################################################

$frames_read = 0;

eval {
    my $t = Term::TtyRec::Plus->new(
        infile => "t/simple.ttyrec",
    );
    my $time = 0;

    while (my $frame_ref = $t->grep("I tell ya,", [qw/grep() was jsn's idea!!/])) {
        ++$frames_read;
        $time += $frame_ref->{diff};
    }
};

is($frames_read, 0, "no frames read");
like($@, qr/Each of grep\(\)'s arguments must be a subroutine, regular expression, or string;/, "\$@ contains the correct error");

#!/usr/bin/env perl

# Test sharpened ionian keys
# Skip some chords in scales with enharmonic notes but don't parse

use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::ToRoman';

my @notes = qw/ C C# Db D D# Eb E Fb E# Fb F F# Gb G G# Ab A A# Bb B B# Cb /;

my @romans = qw/ I bii ii biii iii IV bV V bvi vi bvii vii /;

my %expected = (
    'C'  => 'vii',
    'C#' => 'I',
    'Db' => 'I',
    'D'  => 'bii',
    'D#' => 'ii',
    'Eb' => 'ii',
    'E'  => 'biii',
    'Fb' => 'biii',
    'E#' => 'iii',
    'F'  => 'iii',
    'F#' => 'IV',
    'Gb' => 'IV',
    'G'  => 'bV',
    'G#' => 'V',
    'Ab' => 'V',
    'A'  => 'bvi',
    'A#' => 'vi',
    'Bb' => 'vi',
    'B'  => 'bvii',
    'B#' => 'vii',
    'Cb' => 'bvii',
);

my %values = ();

for my $scale_note ( 'C#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => '', # vi
    'C#' => 'bvii',
    'Db' => 'bvii',
    'D'  => 'vii',
    'D#' => 'I',
    'Eb' => 'I',
    'E'  => 'bii',
    'Fb' => 'bii',
    'E#' => 'ii',
    'F'  => '', # ii
    'F#' => 'biii',
    'Gb' => 'biii',
    'G'  => 'iii',
    'G#' => 'IV',
    'Ab' => 'IV',
    'A'  => 'bV',
    'A#' => 'V',
    'Bb' => 'V',
    'B'  => 'bvi',
    'B#' => 'vi',
    'Cb' => '',
);

%values = ();

for my $scale_note ( 'D#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => '', # V
    'C#' => 'bvi',
    'Db' => 'bvi',
    'D'  => '', # vi
    'D#' => '', # bvii
    'Eb' => '', # bvii
    'E'  => 'vii',
    'Fb' => 'vii',
    'E#' => 'I',
    'F'  => '', # I
    'F#' => 'bii',
    'Gb' => 'bii',
    'G'  => '', # ii
    'G#' => 'biii',
    'Ab' => 'biii',
    'A'  => 'iii',
    'A#' => 'IV',
    'Bb' => 'IV',
    'B'  => 'bV',
    'B#' => 'V',
    'Cb' => 'bV',
);

%values = ();

for my $scale_note ( 'E#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

SKIP: {
    skip 'Double sharps in scale', scalar(@romans);
    for my $roman ( @romans ) {
        ok exists $values{$roman}, "$roman present";
    }
};

%expected = (
    'C'  => 'bV',
    'C#' => 'V',
    'Db' => 'V',
    'D'  => 'bvi',
    'D#' => 'vi',
    'Eb' => 'vi',
    'E'  => 'bvii',
    'Fb' => 'bvii',
    'E#' => 'vii',
    'F'  => 'vii',
    'F#' => 'I',
    'Gb' => 'I',
    'G'  => 'bii',
    'G#' => 'ii',
    'Ab' => 'ii',
    'A'  => 'biii',
    'A#' => 'iii',
    'Bb' => 'iii',
    'B'  => 'IV',
    'B#' => 'bV',
    'Cb' => 'IV',
);

%values = ();

for my $scale_note ( 'F#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => 'iii',
    'C#' => 'IV',
    'Db' => 'IV',
    'D'  => 'bV',
    'D#' => 'V',
    'Eb' => 'V',
    'E'  => 'bvi',
    'Fb' => 'bvi',
    'E#' => 'vi',
    'F'  => '', # vi
    'F#' => 'bvii',
    'Gb' => 'bvii',
    'G'  => 'vii',
    'G#' => 'I',
    'Ab' => 'I',
    'A'  => 'bii',
    'A#' => 'ii',
    'Bb' => 'ii',
    'B'  => 'biii',
    'B#' => 'iii',
    'Cb' => 'biii',
);

%values = ();

for my $scale_note ( 'G#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => '', # ii
    'C#' => 'biii',
    'Db' => 'biii',
    'D'  => 'iii',
    'D#' => 'IV',
    'Eb' => 'IV',
    'E'  => 'bV',
    'Fb' => 'bV',
    'E#' => 'V',
    'F'  => '', # V
    'F#' => 'bvi',
    'Gb' => 'bvi',
    'G'  => '', # vi
    'G#' => 'bvii',
    'Ab' => 'bvii',
    'A'  => 'vii',
    'A#' => 'I',
    'Bb' => 'I',
    'B'  => 'bii',
    'B#' => 'ii',
    'Cb' => 'bii',
);

%values = ();

for my $scale_note ( 'A#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

SKIP: {
    skip 'Double sharps in scale', scalar(@romans);
    for my $roman ( @romans ) {
        ok exists $values{$roman}, "$roman present";
    }
};

%expected = (
    'C'  => '', # I
    'C#' => 'bii',
    'Db' => 'bii',
    'D'  => '', # ii
    'D#' => '', # biii
    'Eb' => '', # biii
    'E'  => 'iii',
    'Fb' => 'iii',
    'E#' => 'IV',
    'F'  => '', # IV
    'F#' => 'bV',
    'Gb' => 'bV',
    'G'  => '', # V
    'G#' => 'bvi',
    'Ab' => 'bvi',
    'A'  => '', # vi
    'A#' => '', # bvii
    'Bb' => '', # bvii
    'B'  => 'vii',
    'B#' => 'I',
    'Cb' => 'vii',
);

%values = ();

for my $scale_note ( 'B#' ) {
    diag "scale_note: $scale_note";

    for my $scale_name (qw/ ionian / ) {
        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            is $roman, $expected{$note}, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

SKIP: {
    skip 'Double sharps in scale', scalar(@romans);
    for my $roman ( @romans ) {
        ok exists $values{$roman}, "$roman present";
    }
};

done_testing();

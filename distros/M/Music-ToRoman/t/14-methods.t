#!/usr/bin/env perl

# Test the natural ionian keys
# Skip some flat chords that have enharmonic scale notes but don't parse

use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::ToRoman';

my @notes = qw/ C C# Db D D# Eb E Fb E# Fb F F# Gb G G# Ab A A# Bb B B# Cb /;

my @romans = qw/ I bii ii biii iii IV bV V bvi vi bvii vii /;

my %expected = (
    'C'  => 'I',
    'C#' => 'bii',
    'Db' => 'bii',
    'D'  => 'ii',
    'D#' => 'biii',
    'Eb' => 'biii',
    'E'  => 'iii',
    'Fb' => 'iii',
    'E#' => 'bV',
    'F'  => 'IV',
    'F#' => 'bV',
    'Gb' => 'bV',
    'G'  => 'V',
    'G#' => 'bvi',
    'Ab' => 'bvi',
    'A'  => 'vi',
    'A#' => 'bvii',
    'Bb' => 'bvii',
    'B'  => 'vii',
    'B#' => 'vii',
    'Cb' => 'vii',
);

my %values = ();

for my $scale_note ( 'C' ) {
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
            is $expected{$note}, $roman, "parsed $note => $roman";
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => 'bvii',
    'C#' => 'vii',
    'Db' => 'vii',
    'D'  => 'I',
    'D#' => 'bii',
    'Eb' => 'bii',
    'E'  => 'ii',
    'Fb' => 'ii',
    'E#' => 'biii',
    'F'  => 'biii',
    'F#' => 'iii',
    'Gb' => 'iii',
    'G'  => 'IV',
    'G#' => 'bV',
    'Ab' => 'bV',
    'A'  => 'V',
    'A#' => 'bvi',
    'Bb' => 'bvi',
    'B'  => 'vi',
    'B#' => 'bvii',
    'Cb' => 'vi',
);

%values = ();

for my $scale_note ( 'D' ) {
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
            is $roman, $expected{$note}, "parsed $note => $roman";
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => 'bvi',
    'C#' => 'vi',
    'Db' => 'vi',
    'D'  => 'bvii',
    'D#' => 'vii',
    'Eb' => 'vii',
    'E'  => 'I',
    'Fb' => 'I',
    'E#' => 'bii',
    'F'  => 'bii',
    'F#' => 'ii',
    'Gb' => 'ii',
    'G'  => 'biii',
    'G#' => 'iii',
    'Ab' => 'iii',
    'A'  => 'IV',
    'A#' => 'bV',
    'Bb' => 'bV',
    'B'  => 'V',
    'B#' => 'bvi',
    'Cb' => 'V',
);

%values = ();

for my $scale_note ( 'E' ) {
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
    'C'  => 'V',
    'C#' => 'bvi',
    'Db' => 'bvi',
    'D'  => 'vi',
    'D#' => 'bvii',
    'Eb' => 'bvii',
    'E'  => 'vii',
    'Fb' => 'vii',
    'E#' => '', # I
    'F'  => 'I',
    'F#' => 'bii',
    'Gb' => 'bii',
    'G'  => 'ii',
    'G#' => 'biii',
    'Ab' => 'biii',
    'A'  => 'iii',
    'A#' => 'IV',
    'Bb' => 'IV',
    'B'  => 'bV',
    'B#' => '', # V
    'Cb' => 'bV',
);

%values = ();

for my $scale_note ( 'F' ) {
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
    'C'  => 'IV',
    'C#' => 'bV',
    'Db' => 'bV',
    'D'  => 'V',
    'D#' => 'bvi',
    'Eb' => 'bvi',
    'E'  => 'vi',
    'Fb' => 'vi',
    'E#' => 'bvii',
    'F'  => 'bvii',
    'F#' => 'vii',
    'Gb' => 'vii',
    'G'  => 'I',
    'G#' => 'bii',
    'Ab' => 'bii',
    'A'  => 'ii',
    'A#' => 'biii',
    'Bb' => 'biii',
    'B'  => 'iii',
    'B#' => '', # IV
    'Cb' => 'iii',
);

%values = ();

for my $scale_note ( 'G' ) {
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
    'C'  => 'biii',
    'C#' => 'iii',
    'Db' => 'iii',
    'D'  => 'IV',
    'D#' => 'bV',
    'Eb' => 'bV',
    'E'  => 'V',
    'Fb' => 'V',
    'E#' => 'bvi',
    'F'  => 'bvi',
    'F#' => 'vi',
    'Gb' => 'vi',
    'G'  => 'bvii',
    'G#' => 'vii',
    'Ab' => 'vii',
    'A'  => 'I',
    'A#' => 'bii',
    'Bb' => 'bii',
    'B'  => 'ii',
    'B#' => 'biii',
    'Cb' => 'ii',
);

%values = ();

for my $scale_note ( 'A' ) {
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
    'C'  => 'bii',
    'C#' => 'ii',
    'Db' => 'ii',
    'D'  => 'biii',
    'D#' => 'iii',
    'Eb' => 'iii',
    'E'  => 'IV',
    'Fb' => 'IV',
    'E#' => 'bV',
    'F'  => 'bV',
    'F#' => 'V',
    'Gb' => 'V',
    'G'  => 'bvi',
    'G#' => 'vi',
    'Ab' => 'vi',
    'A'  => 'bvii',
    'A#' => 'vii',
    'Bb' => 'vii',
    'B'  => 'I',
    'B#' => 'bii',
    'Cb' => 'I',
);

%values = ();

for my $scale_note ( 'B' ) {
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

%values = ();
@values{ grep { $_ } values %expected } = undef;
for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

done_testing();

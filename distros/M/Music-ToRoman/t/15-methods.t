#!/usr/bin/env perl

# Test the flatted ionian keys
# Skip some flat chords that have enharmonic scale notes but don't parse

use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::ToRoman';

my @notes = qw/ C C# Db D D# Eb E Fb E# F F# Gb G G# Ab A A# Bb B B# Cb /;

my @romans = qw/ I bii ii biii iii IV bV V bvi vi bvii vii /;

my %expected = (
    'C'  => 'bii',
    'C#' => '', # ii
    'Db' => 'ii',
    'D'  => 'biii',
    'D#' => '', # iii
    'Eb' => 'iii',
    'E'  => '', # IV
    'Fb' => 'IV',
    'E#' => 'bV',
    'F'  => 'bV',
    'F#' => '', # V
    'Gb' => 'V',
    'G'  => 'bvi',
    'G#' => '', # vi
    'Ab' => 'vi',
    'A'  => 'bvii',
    'A#' => '', # vii
    'Bb' => 'vii',
    'B'  => '', # I
    'B#' => '', # bii
    'Cb' => 'I',
);

my %values = ();

for my $scale_note ( 'Cb' ) {
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
            is $expected{$note}, $roman, "parsed $note => $roman"
                if $expected{$note};
            $values{$roman} = undef;
        }
    }
}

for my $roman ( @romans ) {
    ok exists $values{$roman}, "$roman present";
}

%expected = (
    'C'  => 'vii',
    'C#' => '', # I
    'Db' => 'I',
    'D'  => 'bii',
    'D#' => '', # ii
    'Eb' => 'ii',
    'E'  => 'biii',
    'Fb' => 'biii',
    'E#' => '', # iii
    'F'  => 'iii',
    'F#' => '', # IV
    'Gb' => 'IV',
    'G'  => 'bV',
    'G#' => '', # V
    'Ab' => 'V',
    'A'  => 'bvi',
    'A#' => '', # vi
    'Bb' => 'vi',
    'B'  => 'bvii',
    'B#' => '', # vii
    'Cb' => 'bvii',
);

%values = ();

for my $scale_note ( 'Db' ) {
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
    'C'  => 'vi', # 
    'C#' => 'bvii', # 
    'Db' => 'bvii', # 
    'D'  => 'vii', # 
    'D#' => '', # I
    'Eb' => 'I', # 
    'E'  => 'bii', # 
    'Fb' => 'bii', # 
    'E#' => '', # ii
    'F'  => 'ii', # 
    'F#' => 'biii', # 
    'Gb' => 'biii', # 
    'G'  => 'iii', # 
    'G#' => '', # IV
    'Ab' => 'IV', # 
    'A'  => 'bV', # 
    'A#' => '', # V
    'Bb' => 'V', # 
    'B'  => 'bvi', # 
    'B#' => '', # vi
    'Cb' => 'bvi', # 
);

%values = ();

for my $scale_note ( 'Eb' ) {
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
    'C'  => 'bvi', # 
    'C#' => '', # vi
    'Db' => 'vi', # 
    'D'  => 'bvii', # 
    'D#' => '', # vii
    'Eb' => 'vii', # 
    'E'  => '', # I
    'Fb' => 'I', # 
    'E#' => 'bii', # 
    'F'  => 'bii', # 
    'F#' => '', # ii
    'Gb' => 'ii', # 
    'G'  => 'biii', # 
    'G#' => '', # iii
    'Ab' => 'iii', # 
    'A'  => '', # IV
    'A#' => '', # bV
    'Bb' => '', # bV
    'B'  => '', # V
    'B#' => '', # bvi
    'Cb' => 'V', # 
);

%values = ();

for my $scale_note ( 'Fb' ) {
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
    skip 'Double flat in scale', scalar(@romans);
    for my $roman ( @romans ) {
        ok exists $values{$roman}, "$roman present";
    }
};

%expected = (
    'C'  => 'bV', # 
    'C#' => '', # V
    'Db' => 'V', # 
    'D'  => 'bvi', # 
    'D#' => '', # vi
    'Eb' => 'vi', # 
    'E'  => 'bvii', # 
    'Fb' => 'bvii', # 
    'E#' => 'vii', # *
    'F'  => 'vii', # 
    'F#' => '', # I
    'Gb' => 'I', # 
    'G'  => 'bii', # 
    'G#' => '', # ii
    'Ab' => 'ii', # 
    'A'  => 'biii', # 
    'A#' => '', # iii
    'Bb' => 'iii', # 
    'B'  => '', # IV
    'B#' => '', # bV
    'Cb' => 'IV', # 
);

%values = ();

for my $scale_note ( 'Gb' ) {
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
    'C'  => 'iii', # 
    'C#' => '', # IV
    'Db' => 'IV', # 
    'D'  => 'bV', # 
    'D#' => '', # V
    'Eb' => 'V', # 
    'E'  => 'bvi', # 
    'Fb' => 'bvi', # 
    'E#' => '', # vi
    'F'  => 'vi', # 
    'F#' => 'bvii', # 
    'Gb' => 'bvii', # 
    'G'  => 'vii', # 
    'G#' => '', # I
    'Ab' => 'I', # 
    'A'  => 'bii', # 
    'A#' => '', # ii
    'Bb' => 'ii', # 
    'B'  => 'biii', # 
    'B#' => '', # iii
    'Cb' => 'biii', # 
);

%values = ();

for my $scale_note ( 'Ab' ) {
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
    'C'  => 'ii', # 
    'C#' => 'biii', # 
    'Db' => 'biii', # 
    'D'  => 'iii', # 
    'D#' => '', # IV
    'Eb' => 'IV', # 
    'E'  => 'bV', # 
    'Fb' => 'bV', # 
    'E#' => '', # V
    'F'  => 'V', # 
    'F#' => 'bvi', # 
    'Gb' => 'bvi', # 
    'G'  => 'vi', # 
    'G#' => 'bvii', # 
    'Ab' => 'bvii', # 
    'A'  => 'vii', # 
    'A#' => '', # I
    'Bb' => 'I', # 
    'B'  => 'bii', # 
    'B#' => '', # ii
    'Cb' => 'bii', # 
);

%values = ();

for my $scale_note ( 'Bb' ) {
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

done_testing();

#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ModalFunction';

# The generated Prolog database is only correct if every note is spelled with flats and never sharps.

subtest modes_spelled_flat => sub {
    my $obj = Music::ModalFunction->new;
    my $database = $obj->_database;

    # G ionian's 7th degree is F#, stored as the "leading_tone" (dim, r_vii) chord.
    like $database,
        qr/\Qchord_key(gb, dim, g, ionian, leading_tone, r_vii).\E/,
        'F# in G ionian is stored flat-spelled as gb';

    unlike $database, qr/\Qchord_key(fs,\E/,
        'F# in G ionian is NOT stored in MIDI::Util s/f style (fs)';
    unlike $database, qr/\Qchord_key(f#,\E/,
        'F# in G ionian is NOT stored as an unconverted sharp (f#)';

    # D ionian's 7th degree is C#, stored as leading_tone (dim, r_vii).
    like $database,
        qr/\Qchord_key(db, dim, d, ionian, leading_tone, r_vii).\E/,
        'C# in D ionian is stored flat-spelled as db';

    unlike $database, qr/\Qchord_key(cs,\E/,
        'C# in D ionian is NOT stored in MIDI::Util s/f style (cs)';
    unlike $database, qr/\Qchord_key(c#,\E/,
        'C# in D ionian is NOT stored as an unconverted sharp (c#)';
};

subtest scales_spelled_flat => sub {
    my $obj = Music::ModalFunction->new(use_scales => 1);
    my $database = $obj->_database;

    # D harmonic minor's 7th degree is C#, stored as subtonic (dim, r_vii).
    like $database,
        qr/\Qchord_key(db, dim, d, harmonic_minor, subtonic, r_vii).\E/,
        'C# in D harmonic_minor is stored flat-spelled as db';

    unlike $database, qr/\Qchord_key(cs,\E/,
        'C# in D harmonic_minor is NOT stored in MIDI::Util s/f style (cs)';
    unlike $database, qr/\Qchord_key(c#,\E/,
        'C# in D harmonic_minor is NOT stored as an unconverted sharp (c#)';
};

done_testing();

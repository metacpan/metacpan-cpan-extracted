#!perl
use strict;
use warnings;
use File::Cmp ();
use Music::Scala;
use Test::Most;

plan tests => 52;

my $deeply = \&eq_or_diff;

my $scala = Music::Scala->new;
isa_ok($scala, 'Music::Scala');

is($scala->get_concertfreq, 440, 'default concert frequency');
is($scala->get_description, '',  'default description');
dies_ok(sub { $scala->get_notes }, 'get_notes before read_scala');

# for MIDI/equal temperament reference operations
is($scala->freq2pitch(440), 69,  'frequency to pitch, MIDI ref freq');
is($scala->pitch2freq(69),  440, 'pitch to frequency, MIDI ref pitch');

dies_ok(sub { $scala->read_scala(file => 'Makefile.PL') },
    'invalid scala file');

# Notable for having both ratios and cents, as well as funny ISO 8859-1
# characters in the description.
isa_ok(
    $scala->read_scala(
        binmode => ':encoding(iso-8859-1):crlf',
        file    => 'groenewald_bach.scl',
    ),
    'Music::Scala'
);
is( $scala->get_description,
    "J\x{fc}rgen Gr\x{f6}newald, simplified Bach temperament, Ars Organi vol.57 no.1, March 2009, p.39",
    'Latin 1 infested'
);
$deeply->(
    [ $scala->get_notes ],
    [   qw{256/243 189.25008 32/27 386.60605 4/3 1024/729 693.17509 128/81 887.27506 16/9 1086.80812 2/1}
    ],
    'Bach temperament'
);

$deeply->(
    [   map { sprintf "%.2f", $_ } $scala->interval2freq(0, 12, 24, -12, -24, 1, 2, 3)
    ],
    [ map { sprintf "%.2f", $_ } 440, 880, 1760, 220, 110, 463.54, 490.83, 521.48 ],
    'frequency conversion'
);

# relative/absolute interval methods
$deeply->([ $scala->abs2rel(qw/1 2 3/) ], [qw/1 1 1/]);
$deeply->([ $scala->rel2abs(qw/1 1 1/) ], [qw/1 2 3/]);

# and a slightly more complicated round trip (with rounding as deeply
# tests are picky about 100.0 not being equal to 100 or such)
my @cents = map { sprintf "%.1f", $_ } $scala->get_cents;
$deeply->(
    [ map { sprintf "%.1f", $_ } $scala->rel2abs($scala->abs2rel(@cents)) ],
    \@cents
);

# broken on Windows. no idea why, possibly due to Windows Doing Stuff
# with crlf or encodings or something?
# http://www.cpantesters.org/cpan/report/fbe42eb7-6c68-1014-a08d-d1597c3ca14f
SKIP: {
    skip "broken on Windows", 3 if $^O =~ m/Win32/;
    lives_ok {
        isa_ok(
            $scala->write_scala(
                binmode => ':encoding(iso-8859-1):crlf',
                file    => 't/groenewald_bach.scl',
            ),
            'Music::Scala'
        );
    };
    ok( File::Cmp::fcmp(
            'groenewald_bach.scl', 't/groenewald_bach.scl', binmode => ':raw'
        )
    ) or check_groenewald();
}

# These were copied & pasted from scala site, plus blank desc and number
# of subsequent notes to create a minimally valid file.
$scala->read_scala(file => 'valid-pitch-lines.scl');
is($scala->get_description, 'this is a test', 'desc');
$deeply->(
    [ $scala->get_notes ],
    [qw{81/64 408.0 408. 5/1 -5.0 10/20 100.0 100.0 5/4}],
    'valid pitch lines'
);

$scala = Music::Scala->new(MAX_LINES => 1);
dies_ok(sub { $scala->read_scala(file => 'groenewald_bach.scl') },
    'absurd MAX_LINES to cause exception');

# Global binmode specifier, (testing not crlf is tricky, as Windows systems
# assume it by default, blah blah blah)
$scala = Music::Scala->new(binmode => ':encoding(iso-8859-1):crlf');
$scala->read_scala(file => 'groenewald_bach.scl');
is( $scala->get_description,
    "J\x{fc}rgen Gr\x{f6}newald, simplified Bach temperament, Ars Organi vol.57 no.1, March 2009, p.39",
    'Latin 1 infested II'
);
$deeply->(
    [ $scala->get_notes ],
    [   qw{256/243 189.25008 32/27 386.60605 4/3 1024/729 693.17509 128/81 887.27506 16/9 1086.80812 2/1}
    ],
    'Bach temperament'
);

is($scala->set_description('test'), 'test');
isa_ok($scala->set_notes([qw{256/243 9/8}]), 'Music::Scala');

my $output = '';
open my $ofh, '>', \$output or die 'could not open in-memory fh ' . $!;
isa_ok($scala->write_scala(fh => $ofh), 'Music::Scala');
close $ofh;
is($output, "!\r\n!\r\ntest\r\n 2\r\n!\r\n 256/243\r\n 9/8\r\n",
    'output to fh');

is($scala->set_concertfreq(123.4), 123.4);
is($scala->get_concertfreq, 123.4, 'custom concert frequency');

# more cents testing - via slendro_ky2.scl
$scala = Music::Scala->new(concertfreq => 295);
is($scala->get_concertfreq, 295, 'check cf via new');

# NOTE Perl will map things like a bare 1200.000 to '1200' which then
# becomes the ratio 1200/1 which is wrong.
$scala->set_notes(250.868, 483.311, 715.595, 951.130, '1200.000');
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->interval2freq(0, 5, 10, -5, -10) ],
    [ map { sprintf "%.2f", $_ } 295, 590, 1180, 147.5, 73.75 ],
    'frequency conversion'
);

# file => via new() to save on then typing read_scala out
$scala = Music::Scala->new(file => 'valid-pitch-lines.scl');
is($scala->get_description, 'this is a test', 'get description');

is($scala->get_binmode, undef, 'default binmode');
is($scala->set_binmode(':crlf'), ':crlf');
is($scala->get_binmode, ':crlf', 'custom binmode');

# another edge case is scales that begin with 1/1, which is implicit in
# this module, so must be dealt with if present
$scala->read_scala('slen_pel16.scl');
is(($scala->get_cents)[0], '150.000', 'check that 1/1 removed at head');

$scala->set_notes('2/1', '1200.0', '5/4');

$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->notes2cents($scala->get_notes) ],
    [ map { sprintf "%.2f", $_ } 1200, 1200, 386.31 ],
    'notes2cents'
);

$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->notes2ratios($scala->get_notes) ],
    [ map { sprintf "%.2f", $_ } 2, 2, 5 / 4 ],
    'notes2ratios'
);

$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->get_cents ],
    [ map { sprintf "%.2f", $_ } 1200, 1200, 386.31 ],
    'notes2ratios'
);
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->get_ratios ],
    [ map { sprintf "%.2f", $_ } 2, 2, 5 / 4 ],
    'notes2ratios'
);

is($scala->ratio2cents(2, 0),    1200, 'ratio2cents octave');
is($scala->cents2ratio(1200, 0), 2,    'cents2ratio octave');

is($scala->ratio2cents(5 / 4),
    386.31, 'ratio2cents natural chromatic major third');
is($scala->cents2ratio(386.31), sprintf("%.2f", 5 / 4), 'cents2ratio octave');

isa_ok($scala->set_by_frequency(440, 880), 'Music::Scala');
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->get_ratios ],
    [ map { sprintf "%.2f", $_ } 2 ],
    'notes2ratios'
);

$scala->set_by_frequency([ 440, 880, 1760 ]);
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->get_ratios ],
    [ map { sprintf "%.2f", $_ } 2, 4 ],
    'notes2ratios'
);

$scala->read_scala(file => 'equal.scl');
ok($scala->is_octavish, 'equal temperament better be "octavish"');

# interval2freq had a negative interval bug in < 0.83, as I only tested
# negative "octaves," and not the intervening negative intervals. Whoops!
# So must check how MIDI numbers compare to interval calculations over a
# few octaves, both below and above the concert pitch (69/A440).
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->interval2freq(-26 .. 26) ],
    [ map { sprintf "%.2f", $scala->pitch2freq($_) } 43 .. 95 ],
    'interval2freq equal pitch2freq over range'
);

# except equal temperament is a *bad* test by virtue of equally dividing
# the octave: you do not know if you're counting up when you should
# instead actually be counting down, or the reverse.
$scala->read_scala(file => 'carlos_super.scl');
$deeply->(
    [   map { sprintf "%.2f", $_ }
          $scala->interval2freq(-13, -12, -11, -1, 0, 1, 12, 13)
    ],
    [ map { sprintf "%.2f", $_ } 206.25, 220, 233.75, 412.5, 440, 467.5, 880, 935 ],
    'interval2freq for just scale'
);

# and then there's (uncommon (13% of archive)) non-octave bounded scales
# that will totally not match up with any MIDI pitch numbers but still
# can have interval calculations applied to them...
$scala->read_scala(file => 'xylophone2.scl');
ok(!$scala->is_octavish, 'not octave bounded');
# not a very good test, as worked out numbers by hand mostly using the
# logic present in this module :/ independent verification would be nice
$deeply->(
    [ map { sprintf "%.2f", $_ } $scala->interval2freq(-1, 0, 1, 10, 11) ],
    [ map { sprintf "%.2f", $_ } qw/392.22 440.00 496.46 1417.23 1599.08/ ],
    'non-octave scale intervale2freq calcs'
);

# paranoia that attribute with reader/writer might use some other name;
# they do not when passed to ->new()
$scala = Music::Scala->new(concertfreq => 123.4);
is($scala->get_concertfreq, 123.4, 'custom concert frequency via new');

# what the heck got written to the output file?
sub check_groenewald {
    open my $fh, '<', 't/groenewald_bach.scl'
      or BAIL_OUT("could not open t/groenewald_bach.scl: $!");
    diag sprintf "%vx", do { local $/; readline $fh };
}

#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Music::LilyPondUtil;

########################################################################
#
# class methods (just one. okay, two).

my $lyu = Music::LilyPondUtil->new;
isa_ok( $lyu, 'Music::LilyPondUtil' );

is( Music::LilyPondUtil->patch2instrument(10),   'music box', 'a box' );
is( Music::LilyPondUtil->patch2instrument(-261), '',          'no such patch' );

########################################################################
#
# "piano white key" utility method

is( $lyu->diatonic_pitch(q{c'}),     60, 'diatonic to diatonic' );
is( $lyu->diatonic_pitch(q{ceses'}), 60, 'not diatonic to diatonic' );

########################################################################
#
# register utility methods (used internally by other methods)

is( $lyu->reg_num2sym(3), q{,},  'num2sym check' );
is( $lyu->reg_num2sym(4), q{},   'num2sym check' );
is( $lyu->reg_num2sym(6), q{''}, 'num2sym check' );

is( $lyu->reg_sym2num(q{,}),  3, 'sym2num check' );
is( $lyu->reg_sym2num(q{}),   4, 'sym2num check' );
is( $lyu->reg_sym2num(q{''}), 6, 'sym2num check' );

########################################################################
#
# notes2pitches - absolute mode (default)

is( $lyu->notes2pitches('c'), 48, 'convert c to pitch' );
is_deeply(
  [ $lyu->notes2pitches(qw/c d e r f/) ],
  [ qw/48 50 52/, undef, 53 ],
  'convert notes to pitches'
);

is( $lyu->notes2pitches(11), 11, 'pass through raw pitch number' );
# or whatever
is_deeply(
  [ $lyu->notes2pitches( -42, 9999 ) ],
  [ -42, 9999 ],
  'pass through raw pitch numbers'
);

# must worry about chromatics that jump the register
is( $lyu->notes2pitches('ces'),     47, 'convert ces to pitch' );
is( $lyu->notes2pitches(q{bisis,}), 49, 'convert bisis, to pitch' );

is_deeply(
  [ $lyu->notes2pitches( split ' ', q{d,, fis' aes g, bis''' c'' eisis'} ) ],
  [qw/26 66 56 43 96 72 66/],
  'leaps and bounds'
);

# however, "gesture" or "fish" type words will pass muster, as the
# current code does not account for duration or other lilypond elements,
# or otherwise check the tail of the input.
dies_ok( sub { $lyu->notes2pitches('quack') },
  "if it quacks like a note, it's a duck, not a note" );

########################################################################
#
# notes2pitches - relative mode

is( $lyu->mode('relative'), 'relative', 'switch to relative' );

# some simple no-leap foo
is_deeply(
  [ $lyu->notes2pitches(qw/c c f c b c g c fis/) ],
  [ 48, 48, 53, 48, 47, 48, 43, 48, 54 ],
  'convert notes to pitches'
);

# all the no-leap sharp tritones
is_deeply(
  [ $lyu->notes2pitches(
      qw/b f b c fis c cis g cis d gis d dis a dis e ais e f b f fis c fis g cis g gis d gis a dis a ais e ais/
    )
  ],
  [ qw/59 53 59 60 66 60 61 55 61 62 68 62 63 57 63 64 70 64 65 71 65 66 60 66 67 73 67 68 62 68 69 75 69 70 64 70/
  ],
  'relative sharps tritone no leap'
);

# tricky - returns pitch of the diatonic, as relative calculations use those
is( $lyu->prev_note(q{aes'}), 69, 'set previous note' );
is( $lyu->prev_note(q{a'}),   69, 'set previous note' );

is_deeply(
  [ $lyu->notes2pitches(
      split ' ',
      q{c g,, c, geses' c'' ceses c,, ees, bis' b'' bis geses,, bis, ees' bis'' dis gis,, aes, gis' e'' gis f,, gis, bis' ces'' aeses ces,, ges, ces' feses'' ces fis,, e, cis' e'' b e,, fisis, e' g'' ges d,, ges, bes' ges'' e ges,, geses, cis' fisis'' cis des,, cis, dis' cis'' aeses fisis,, eeses, fisis' gisis'' fisis ges,, fisis, des'}
    )
  ],
  [ qw/72 43 36 41 72 70 48 39 48 71 72 41 36 51 72 75 56 44 56 76 80 53 44 60 83 79 59 42 59 87 83 66 52 61 88 83 64 55 64 91 90 62 54 70 90 88 66 53 73 103 97 73 61 75 97 91 67 50 67 93 91 66 55 61/
  ],
  'random complicated foo'
);

########################################################################
#
# p2ly - absolute mode (default)

# KLUGE on min_pitch to fit old tests to new defaults
$lyu = Music::LilyPondUtil->new( min_pitch => -30 );

is( $lyu->p2ly(60), q{c'},  q{absolute 60 -> c'} );
is( $lyu->p2ly(59), q{b},   q{absolute 59 -> b} );
is( $lyu->p2ly(45), q{a,},  q{absolute 45 -> a,} );
is( $lyu->p2ly(74), q{d''}, q{absolute 74 -> d''} );

is( $lyu->p2ly(61), q{cis'}, q{absolute default chrome 61 -> cis'} );
$lyu->chrome('flats');
is( $lyu->p2ly(61), q{des'}, q{absolute flat chrome 61 -> des'} );
$lyu->chrome('sharps');
is( $lyu->p2ly(61), q{cis'}, q{absolute sharp chrome 61 -> cis'} );

is_deeply(
  [ $lyu->p2ly(qw{60 74 45}) ],
  [ "c'", "d''", "a," ],
  q{absolute various leaps}
);

########################################################################
#
# p2ly - relative, sharps

$lyu->mode('relative');
is( $lyu->chrome('sharps'), 'sharps', 'switch to sharps' );

is_deeply( [ $lyu->p2ly(qw{0 2 4 5 7 9 11 12}) ],
  [qw{c d e f g a b c}], q{relative octave run} );

# tritones are tricky in relative mode
is_deeply(
  [ $lyu->p2ly(
      qw{59 53 59 60 66 60 61 55 61 62 68 62 63 57 63 64 70 64 65 71 65 66 60 66 67 73 67 68 62 68 69 75 69 70 64 70}
    )
  ],
  [ split ' ',
    q{b f b c fis c cis g cis d gis d dis a dis e ais e f b f fis c fis g cis g gis d gis a dis a ais e ais}
  ],
  'relative sharps tritone no leap'
);

is_deeply(
  [ $lyu->p2ly(
      qw{59 65 59 60 54 60 61 67 61 62 56 62 63 69 63 64 58 64 65 59 65 66 72 66 67 61 67 68 74 68 69 63 69 70 76 70}
    )
  ],
  [ split ' ',
    q{b f' b, c fis, c' cis g' cis, d gis, d' dis a' dis, e ais, e' f b, f' fis c' fis, g cis, g' gis d' gis, a dis, a' ais e' ais,}
  ],
  'relative sharps tritone leap'
);

is_deeply(
  [ $lyu->p2ly(
      qw{60 62 60 65 60 66 60 67 60 69 60 78 60 79 60 62 67 62 68 62 69 62 80 62 81 62}
    )
  ],
  [ split ' ',
    q{c d c f c fis c g' c, a' c, fis' c, g'' c,, d g d gis d a' d, gis' d, a'' d,,}
  ],
  q{relative sharps positive}
);

# As before, just transposed the pitches down to ensure negative numbers
# processed the same (sometimes the pitch "0" means "middle c or
# something" below which the notes can wander).
is_deeply(
  [ $lyu->p2ly(
      qw{-12 -10 -12 -7 -12 -6 -12 -5 -12 -3 -12 6 -12 7 -12 -10 -5 -10 -4 -10 -3 -10 8 -10 9 -10}
    )
  ],
  [ split ' ',
    q{c d c f c fis c g' c, a' c, fis' c, g'' c,, d g d gis d a' d, gis' d, a'' d,,}
  ],
  q{relative sharps negative}
);

is_deeply(
  [ $lyu->p2ly(qw{60 54 60 55 60 62 56 62}) ],
  [ split ' ', q{c fis, c' g c d gis, d'} ],
  q{relative sharps positive downwards}
);

is_deeply(
  [ $lyu->p2ly(qw{-12 -18 -12 -17 -12 -10 -16 -10}) ],
  [ split ' ', q{c fis, c' g c d gis, d'} ],
  q{relative sharps negative downwards}
);

########################################################################
#
# p2ly - relative, flats

is( $lyu->chrome('flats'), 'flats', 'switch to flats' );

# tritones are tricky in relative mode
is_deeply(
  [ $lyu->p2ly(
      qw{59 53 59 60 54 60 61 67 61 62 56 62 63 69 63 64 58 64 65 71 65 66 72 66 67 61 67 68 74 68 69 63 69 70 76 70}
    )
  ],
  [ split ' ',
    q{b f b c ges c des g des d aes d ees a ees e bes e f b f ges c ges g des g aes d aes a ees a bes e bes}
  ],
  'relative flats tritone no leap'
);

is_deeply(
  [ $lyu->p2ly(
      qw{59 65 59 60 66 60 61 55 61 62 68 62 63 57 63 64 70 64 65 59 65 66 60 66 67 73 67 68 62 68 69 75 69 70 64 70}
    )
  ],
  [ split ' ',
    q{b f' b, c ges' c, des g, des' d aes' d, ees a, ees' e bes' e, f b, f' ges c, ges' g des' g, aes d, aes' a ees' a, bes e, bes'}
  ],
  'relative sharps tritone leap'
);

is_deeply(
  [ $lyu->p2ly(
      qw{60 62 60 65 60 66 60 67 60 69 60 78 60 79 60 62 67 62 68 62 69 62 80 62 81 62}
    )
  ],
  [ split ' ',
    q{c d c f c ges' c, g' c, a' c, ges'' c,, g'' c,, d g d aes' d, a' d, aes'' d,, a'' d,,}
  ],
  q{relative flats positive}
);

is_deeply(
  [ $lyu->p2ly(
      qw{-24 -22 -24 -19 -24 -18 -24 -17 -24 -15 -24 -6 -24 -5 -24 -22 -17 -22 -16 -22 -15 -22 -4 -22 -3 -22}
    )
  ],
  [ split ' ',
    q{c d c f c ges' c, g' c, a' c, ges'' c,, g'' c,, d g d aes' d, a' d, aes'' d,, a'' d,,}
  ],
  q{relative flats negative}
);

is_deeply(
  [ $lyu->p2ly(qw{60 54 60 42 60 62 56 62 44 62}) ],
  [ split ' ', q{c ges c ges, c' d aes d aes, d'} ],
  q{relative flats positive downwards}
);

is_deeply(
  [ $lyu->p2ly(qw{-12 -18 -12 -30 -12 -10 -16 -10 -28 -10}) ],
  [ split ' ', q{c ges c ges, c' d aes d aes, d'} ],
  q{relative flats negative downwards}
);

########################################################################
#
# notes2pitches params

$lyu = Music::LilyPondUtil->new( ignore_register => 1 );
ok( $lyu->ignore_register, 'ignore_register is enabled' );
is_deeply( [ $lyu->notes2pitches(qw/c d e f/) ],
  [qw/0 2 4 5/], 'convert notes to tone-row pitches' );
$lyu->ignore_register(0);
is_deeply( [ $lyu->notes2pitches(qw/c d e f/) ],
  [qw/48 50 52 53/], 'convert notes to pitches' );

$lyu = Music::LilyPondUtil->new( strip_rests => 1 );
ok( $lyu->strip_rests, 'strip_rests is enabled' );
is_deeply( [ $lyu->notes2pitches(qw/c d e r f/) ],
  [qw/48 50 52 53/], 'convert notes to pitches, stripping rests' );
$lyu->strip_rests(0);
is_deeply(
  [ $lyu->notes2pitches(qw/c r c/) ],
  [ 48, undef, 48 ],
  'convert notes to pitches'
);

########################################################################
#
# p2ly params

$lyu = Music::LilyPondUtil->new( mode => 'relative' );
is( $lyu->mode, 'relative' );

$lyu = Music::LilyPondUtil->new( chrome => 'flats' );
is( $lyu->chrome, 'flats' );

$lyu = Music::LilyPondUtil->new( keep_state => 0 );
ok( !$lyu->keep_state, 'keep_state is disabled' );

is_deeply( [ $lyu->p2ly(qw/0 12 24 36/) ],
  [qw/c c c c/], q{state disabled should nix registers relative} );

$lyu->mode('absolute');
is_deeply( [ $lyu->p2ly(qw/0 12 24 36/) ],
  [qw/c c c c/], q{state disabled should nix registers absolute} );

$lyu->keep_state(1);
ok( $lyu->keep_state, 'keep_state is enabled' );

$lyu = Music::LilyPondUtil->new( sticky_state => 1 );
ok( $lyu->sticky_state, 'sticky_state is enabled' );

$lyu->mode('relative');
my @notes = $lyu->p2ly(0);
for my $i ( 0 .. 2 ) {
  push @notes, $lyu->p2ly( 12 + $i * 12 );
}
is_deeply(
  \@notes,
  [ split ' ', "c c' c' c'" ],
  'sticky state across p2ly calls'
);

is( $lyu->prev_pitch, 36, 'previous sticky pitch' );

# Can also set previous "pitch" to be a lilypond note. NOTE uses
# diatonic_pitch internally, might need new n2p or otherwise simple
# internal routine for such cases if run into conflicts?
is( $lyu->prev_pitch(q{c'}), 60, 'previous sticky pitch' );

# NOTE the d,,,,, is expected, as pitches are pitches, and unlike note
# names do not magically jump to the desired register just because
# prev_pitch was set to something. Transpose all the numbers to the
# particular register if necessary (e.g. $n += 60 for @pitches, or use
# some method from Music::Canon).
$deeply->(
  [ $lyu->p2ly(qw/2 9 5 2 1 2 4 5/) ],
  [ 'd,,,,,', qw/a' f d cis d e f/ ],
  'p2ly after prev_pitch relative mode'
);

$lyu->clear_prev_pitch;
ok( !defined $lyu->prev_pitch, 'previous pitch cleared' );

$lyu->sticky_state(0);
ok( !$lyu->sticky_state, 'sticky_state is disabled' );

########################################################################
#
# min/max pitch constraints

$lyu = Music::LilyPondUtil->new;
dies_ok( sub { $lyu->p2ly(-1) }, "min_pitch default" );
is( $lyu->p2ly(12), 'c,,,', 'low pitch conversion' );
dies_ok( sub { $lyu->p2ly(109) }, "max_pitch default" );
is( $lyu->p2ly(108), q{c'''''}, 'high pitch conversion' );

$lyu = Music::LilyPondUtil->new( min_pitch => 21, max_pitch => 60 );
dies_ok( sub { $lyu->p2ly(12) }, "custom min_pitch" );
dies_ok( sub { $lyu->p2ly(61) }, "custom max_pitch" );

$lyu = Music::LilyPondUtil->new(
  min_pitch_hook => sub { 'r' },
  max_pitch_hook => sub { 's' },
);

is( $lyu->p2ly(-999), 'r', 'min pitch hook' );
is( $lyu->p2ly(999),  's', 'max pitch hook' );

plan tests => 75;

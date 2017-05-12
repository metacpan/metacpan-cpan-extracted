#!perl

use Test::More;

use Music::Gestalt;
use MIDI;
use File::Spec::Functions qw(catfile);

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 10 + 10 + 10;
}

# These test verify reading and modifying the properties of a gestalt.

# ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)
my $score = [
    ['note', 50,  50, 1, 20,  10],
    ['note', 150, 50, 1, 40,  20],
    ['note', 250, 50, 1, 80,  40],
    ['note', 350, 50, 1, 120, 50]];

my $g = Music::Gestalt->new(score => $score);
isa_ok($g, 'Music::Gestalt');

is($g->PitchLowest(),  20);
is($g->PitchHighest(), 120);
is($g->PitchMiddle(),  70);
is($g->PitchRange(),   50);

is($g->VelocityLowest(),  10);
is($g->VelocityHighest(), 50);
is($g->VelocityMiddle(),  30);
is($g->VelocityRange(),   20);

is($g->Duration(), 400);

# Test properties of empty gestalt

$g = Music::Gestalt->new();
isa_ok($g, 'Music::Gestalt');

is($g->PitchLowest(),  undef);
is($g->PitchHighest(), undef);
is($g->PitchMiddle(),  undef);
is($g->PitchRange(),   undef);

is($g->VelocityLowest(),  undef);
is($g->VelocityHighest(), undef);
is($g->VelocityMiddle(),  undef);
is($g->VelocityRange(),   undef);

is($g->Duration(), 0);

# Test properties of gestalt with single note

$g = Music::Gestalt->new(score => [['note', 0, 100, 1, 60, 100]]);
isa_ok($g, 'Music::Gestalt');

is($g->PitchLowest(),  60);
is($g->PitchHighest(), 60);
is($g->PitchMiddle(),  60);
is($g->PitchRange(),   0);

is($g->VelocityLowest(),  100);
is($g->VelocityHighest(), 100);
is($g->VelocityMiddle(),  100);
is($g->VelocityRange(),   0);

is($g->Duration(), 100);
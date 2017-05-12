#!perl

use Test::More;

use Music::Gestalt;
use MIDI;
use File::Spec::Functions qw(catfile);

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 2 + 4 + 12 + 12;
}

# These test verify appending different gestalts.

# ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)
my @scores = (
    [['note', 0, 100, 1, 60, 40], ['note', 100, 100, 1, 64, 60]],
    [['note', 0, 100, 1, 67, 80], ['note', 100, 100, 1, 72, 100]]);

my @gestalts = map { Music::Gestalt->new(score => $_) } @scores;

isa_ok($gestalts[$_], 'Music::Gestalt') foreach (0 .. $#gestalts);

my $g = Music::Gestalt->new();
is(scalar $g->Notes(), 0);
$g->Append();
is(scalar $g->Notes(), 0);
$g->Append('nonsense', ['some', 'array']);
is(scalar $g->Notes(), 0);
$g->Append(Music::Gestalt->new());
is(scalar $g->Notes(), 0);

$g->Append($gestalts[0]);

is($g->PitchLowest(),  60);
is($g->PitchHighest(), 64);
is($g->PitchMiddle(),  62);
is($g->PitchRange(),   2);

is($g->VelocityLowest(),  40);
is($g->VelocityHighest(), 60);
is($g->VelocityMiddle(),  50);
is($g->VelocityRange(),   10);

is($g->Duration(), 200);
is(scalar $g->Notes(), 2);

my $score = $g->AsScore();
is(scalar @$score, 2);
is_deeply($score,
    [
        ['note', 0,   100, 1, 60, 40],
        ['note', 100, 100, 1, 64, 60]]);

$g->Append($gestalts[1]);

is($g->PitchLowest(),  60);
is($g->PitchHighest(), 72);
is($g->PitchMiddle(),  66);
is($g->PitchRange(),   6);

is($g->VelocityLowest(),  40);
is($g->VelocityHighest(), 100);
is($g->VelocityMiddle(),  70);
is($g->VelocityRange(),   30);

is($g->Duration(), 400);
is(scalar $g->Notes(), 4);

$score = $g->AsScore();
is(scalar @$score, 4);
is_deeply($score,
    [
        ['note', 0,   100, 1, 60, 40],
        ['note', 100, 100, 1, 64, 60],
        ['note', 200, 100, 1, 67, 80],
        ['note', 300, 100, 1, 72, 100]]);

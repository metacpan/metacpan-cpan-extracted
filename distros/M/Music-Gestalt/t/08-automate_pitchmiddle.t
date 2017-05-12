#!perl

use Test::More;

use Music::Gestalt;
use MIDI;

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 137 + 9;
}

# ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)
my $score = [
    ['note', 50,  50, 1, 60,  60],
    ['note', 150, 50, 1, 60,  60],
    ['note', 250, 50, 1, 60,  60],
    ['note', 350, 50, 1, 60,  60]];

my $g = Music::Gestalt->new(score => $score);
my $g2 = Music::Gestalt->new(score => $score);

# --- AutomatePitchMiddleAbs ---
is_deeply($g->AsScore(), $score);
$g->AutomatePitchMiddleAbs();
is_deeply($g->AsScore(), $score);
$g->AutomatePitchMiddleAbs(-1);
$g2->PitchMiddle(0);
is_deeply($g->AsScore(), $g2->AsScore());
foreach my $i (0..127) {
    $g->AutomatePitchMiddleAbs($i);
    $g2->PitchMiddle($i);
    is_deeply($g->AsScore(), $g2->AsScore());
}
$g->AutomatePitchMiddleAbs(128);
$g2->PitchMiddle(127);
is_deeply($g->AsScore(), $g2->AsScore());

my $score_pm = [
    ['note', 50,  50, 1, 15,  60],
    ['note', 150, 50, 1, 45,  60],
    ['note', 250, 50, 1, 75,  60],
    ['note', 350, 50, 1, 105,  60]];
$g->AutomatePitchMiddleAbs(0, 120);
is_deeply($g->AsScore(), $score_pm);

$g->AutomatePitchMiddleAbs(120, 0);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 105,  60],
    ['note', 150, 50, 1,  75,  60],
    ['note', 250, 50, 1,  45,  60],
    ['note', 350, 50, 1,  15,  60]]);
$g->AutomatePitchMiddleAbs(0, 60, 120);
is_deeply($g->AsScore(), $score_pm);
$g->AutomatePitchMiddleAbs(0, 15, 30, 45, 60, 75, 80, 105, 120);
is_deeply($g->AsScore(), $score_pm);

$g->AutomatePitchMiddleOff();
is_deeply($g->AsScore(), $score);

# --- AutomatePitchMiddleRel ---
$g = Music::Gestalt->new(score => $score);
is_deeply($g->AsScore(), $score);
$g->AutomatePitchMiddleRel();
is_deeply($g->AsScore(), $score);
$g->AutomatePitchMiddleRel(0);
is_deeply($g->AsScore(), [map { my @a = @$_; $a[4] = 0; \@a; } @$score]);
$g->AutomatePitchMiddleRel(1);
is_deeply($g->AsScore(), $score);

$score_pm = [
    ['note', 50,  50, 1,  8, 60],
    ['note', 150, 50, 1, 23, 60],
    ['note', 250, 50, 1, 38, 60],
    ['note', 350, 50, 1, 53, 60]];

$g->AutomatePitchMiddleRel(0, 1);
is_deeply($g->AsScore(), $score_pm);

$g->AutomatePitchMiddleRel(1, 0);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 53, 60],
    ['note', 150, 50, 1, 38, 60],
    ['note', 250, 50, 1, 23, 60],
    ['note', 350, 50, 1,  8, 60]]);

$g->AutomatePitchMiddleRel(0, 0.5, 1);
is_deeply($g->AsScore(), $score_pm);

$g->AutomatePitchMiddleRel(0, 0.2, 0.4, 0.6, 0.8, 1);
is_deeply($g->AsScore(), $score_pm);

$g->AutomatePitchMiddleOff();
is_deeply($g->AsScore(), $score);
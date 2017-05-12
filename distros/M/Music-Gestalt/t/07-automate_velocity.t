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

# --- AutomateVelocityAbs ---
is_deeply($g->AsScore(), $score);
$g->AutomateVelocityAbs();
is_deeply($g->AsScore(), $score);
$g->AutomateVelocityAbs(-1);
is_deeply($g->AsScore(), [map { my @a = @$_; $a[5] = 0; \@a; } @$score]);
foreach my $i (0..127) {
    $g->AutomateVelocityAbs($i);
    is_deeply($g->AsScore(), [map { my @a = @$_; $a[5] = $i; \@a; } @$score]);
}
$g->AutomateVelocityAbs(128);
is_deeply($g->AsScore(), [map { my @a = @$_; $a[5] = 127; \@a; } @$score]);

$g->AutomateVelocityAbs(0, 120);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 60,  15],
    ['note', 150, 50, 1, 60,  45],
    ['note', 250, 50, 1, 60,  75],
    ['note', 350, 50, 1, 60,  105]]);
$g->AutomateVelocityAbs(120, 0);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 60,  105],
    ['note', 150, 50, 1, 60,  75],
    ['note', 250, 50, 1, 60,  45],
    ['note', 350, 50, 1, 60,  15]]);
$g->AutomateVelocityAbs(0, 60, 120);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 60,  15],
    ['note', 150, 50, 1, 60,  45],
    ['note', 250, 50, 1, 60,  75],
    ['note', 350, 50, 1, 60,  105]]);
$g->AutomateVelocityAbs(0, 15, 30, 45, 60, 75, 80, 105, 120);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 60,  15],
    ['note', 150, 50, 1, 60,  45],
    ['note', 250, 50, 1, 60,  75],
    ['note', 350, 50, 1, 60,  105]]);

$g->AutomateVelocityOff();
is_deeply($g->AsScore(), $score);

# --- AutomateVelocityRel ---
is_deeply($g->AsScore(), $score);
$g->AutomateVelocityRel();
is_deeply($g->AsScore(), $score);
$g->AutomateVelocityRel(0);
is_deeply($g->AsScore(), [map { my @a = @$_; $a[5] = 0; \@a; } @$score]);
$g->AutomateVelocityRel(1);
is_deeply($g->AsScore(), $score);

my $score_vr = [
    ['note', 50,  50, 1, 60,  7],
    ['note', 150, 50, 1, 60,  22],
    ['note', 250, 50, 1, 60,  37],
    ['note', 350, 50, 1, 60,  52]];

$g->AutomateVelocityRel(0, 1);
is_deeply($g->AsScore(), $score_vr);

$g->AutomateVelocityRel(1, 0);
is_deeply($g->AsScore(), [
    ['note', 50,  50, 1, 60,  52],
    ['note', 150, 50, 1, 60,  37],
    ['note', 250, 50, 1, 60,  22],
    ['note', 350, 50, 1, 60,   7]]);

$g->AutomateVelocityRel(0, 0.5, 1);
is_deeply($g->AsScore(), $score_vr);

$g->AutomateVelocityRel(0, 0.2, 0.4, 0.6, 0.8, 1);
is_deeply($g->AsScore(), $score_vr);

$g->AutomateVelocityOff();
is_deeply($g->AsScore(), $score);
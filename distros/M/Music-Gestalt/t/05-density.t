#!perl

use Test::More;

use Music::Gestalt;
use MIDI;
use File::Spec::Functions qw(catfile);

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 4 + 9 * 2;
}

# These test verify modifying the density of a gestalt.

# ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)
my $score = [
    ['note', 50,  50, 1, 20,  10],
    ['note', 150, 50, 1, 50,  32],
    ['note', 250, 50, 1, 90,  96],
    ['note', 350, 50, 1, 120, 117],
    ['note', 400, 50, 1, 20,  10],
    ['note', 450, 50, 1, 50,  32],
    ['note', 500, 50, 1, 90,  96],
    ['note', 550, 50, 1, 120, 117]];

my $g = Music::Gestalt->new(score => $score);
is_deeply($g->AsScore(), $score);
is($g->Density(), 1);
is($g->Density(-0.1), 0);
is($g->Density(1.1), 1);

foreach (0..8) {
    is($g->Density($_/8), $_/8);
    is(scalar @{$g->AsScore()}, $_);
}

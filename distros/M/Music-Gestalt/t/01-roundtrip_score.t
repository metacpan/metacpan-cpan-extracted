#!perl

use Test::More;

use Music::Gestalt;
use MIDI;
use File::Spec::Functions qw(catfile);

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 1 + 4 + 100 + 5;
}

# These tests verify that the round-trip score->gestalt->score works
# and that it returns the original score.

my $g = Music::Gestalt->new();
isa_ok($g, 'Music::Gestalt');

# ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)

my @scores = (
    [],
    [['note', 0, 100, 1, 92, 100]],
    [['note', 0, 100, 1, 92, 100], ['note', 0, 100, 1, 92, 100]],
    [
        ['note', 50, 50, 1, 0,   0],
        ['note', 150, 50, 1, 40,  10],
        ['note', 250, 50, 1, 80,  20],
        ['note', 350, 50, 1, 120, 40]]);

foreach my $i (1 .. 100) {
    my @score = ();
    my $start = int(rand(500));
    foreach (1 .. int(rand(10) + 1)) {
        push @score,
          [
            'note',         $start,
            int(rand(500)), int(rand(15) + 1),
            int(rand(128)), int(rand(128))];
        $start += int(rand(500));
    }

    push @scores, [ @score ];
}

foreach (@scores) {
    my $g = Music::Gestalt->new(score => $_);
#    use Data::Dumper;
#    diag(Dumper($g->{notes}));
    is_deeply($g->AsScore(), $_);
}

my $file = catfile('t-data', 'BWV227_Jesu_meine_Freude.mid');

my $opus = MIDI::Opus->new({ from_file => $file });
foreach ($opus->tracks()) { 
    my @events = grep { $_->[0] =~ /^note_(on|off)$/ } $_->events();
    my $score = MIDI::Score::events_r_to_score_r(\@events);
    is_deeply(Music::Gestalt->new(score => $score)->AsScore(), $score);
}

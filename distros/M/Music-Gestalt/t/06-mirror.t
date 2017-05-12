#!perl

use Test::More;

use Music::Gestalt;
use MIDI;
use File::Spec::Functions qw(catfile);

if ($ENV{DEVELOPMENT}) {
    plan skip_all => 'Skipped during development';
} else {
    plan tests => 5 * 3;
}

# These tests verify that the mirroring works

my $file = catfile('t-data', 'BWV227_Jesu_meine_Freude.mid');

my $opus = MIDI::Opus->new({from_file => $file});
foreach ($opus->tracks()) {
    my @events = grep { $_->[0] =~ /^note_(on|off)$/ } $_->events();
    my $score  = MIDI::Score::events_r_to_score_r(\@events);
    my $g      = Music::Gestalt->new(score => $score);

    # ('note_on', I<start_time>, I<duration>, I<channel>, I<note>, I<velocity>)

    $g->MirrorTime();
    $g->MirrorTime();
    is_score($g->AsScore(), $score);

    $g->MirrorPitch();
    $g->MirrorPitch();
    is_score($g->AsScore(), $score);

    $g->MirrorVelocity();
    $g->MirrorVelocity();
    is_score($g->AsScore(), $score);
}

sub is_score {
    my ($s1, $s2) = @_;
    my $tolerance = 0.00001;

    fail(), return () unless scalar @$s1 == @$s2;
    foreach my $i (0 .. $#$s1) {
        fail(), return () unless $s1->[$i]->[0] eq $s1->[$i]->[0];
        for (1 .. 5) {
            fail(), return ()
              unless abs($s1->[$i]->[$_] - $s1->[$i]->[$_]) < $tolerance;
        }
    }
    pass();
}

__END__

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

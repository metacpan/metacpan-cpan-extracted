use v5.36;
use Test::More;
use lib 'lib';
use List::Util qw(sum0);
use Peta::Synth::Engine::Perl;
use Peta::Synth::Patch;
use Peta::Synth::Profile;
use Peta::Synth::Synth;
use Peta::Synth::Voice;

my $rate = 24000;
my $quantum = 512;

# The envelope a voice says it has is the one its controls work out, at
# the end of every quantum: held, let go, killed (all sound off), a drum
# past its length.
{
    my $synth = Peta::Synth::Synth->new(rate => $rate, engine => Peta::Synth::Engine::Perl->new, partials => 8);
    $synth->schedule([
        { time => 0,    type => 'note_on', channel => 0, key => 60, velocity => 100 },
        { time => 0.3,  type => 'note_off', channel => 0, key => 60 },
        { time => 0.1,  type => 'note_on', channel => 9, key => 49, velocity => 100 },
        { time => 0.2,  type => 'note_on', channel => 1, key => 64, velocity => 90 },
        { time => 0.45, type => 'controller', channel => 1, number => 120, value => 0 },
    ]);
    my ($worst, $checked) = (0, 0);
    for (1 .. int($rate / $quantum)) {
        $synth->render_arrays($quantum);
        for my $voice (@{ $synth->{active} }) {
            my $d = abs($voice->{raw_env} - $voice->envelope_at(($synth->now - $voice->{start}) / $rate));
            $worst = $d if $d > $worst;
            $checked++;
        }
    }
    cmp_ok($checked, '>', 50, 'envelope_at: voices checked');
    cmp_ok($worst, '<', 1e-12, 'envelope_at: as controls has it, held, let go, killed, a drum');
}

# When a voice will be silent, foreseen, is when rendering finds it done:
# within the quantum after.
sub rendered_ends ($events) {
    my $synth = Peta::Synth::Synth->new(rate => $rate, engine => Peta::Synth::Engine::Perl->new, partials => 16);
    $synth->schedule($events);
    my %seen;
    my %end;
    while ($synth->busy && $synth->now < 20 * $rate) {
        $synth->render_arrays($quantum);
        my %now = map { $_ => $_ } @{ $synth->{active} };
        $seen{$_} //= $now{$_} for keys %now;
        for my $v (keys %seen) { $end{$v} //= $synth->now / $rate if !$now{$v} }
    }
    return [ sort { $a <=> $b } map { $end{$_} - $seen{$_}{start} / $rate } keys %seen ];
}
sub foreseen_ends ($events) {
    my $synth = Peta::Synth::Synth->new(rate => $rate, engine => Peta::Synth::Engine::Perl->new, partials => 16);
    $synth->schedule($events);
    return [ sort { $a <=> $b } map { $_->{end} - $_->{start} } @{ $synth->foresee } ];
}
my @events = (
    { time => 0,   type => 'program', channel => 0, program => 0 },
    { time => 0,   type => 'note_on', channel => 0, key => 60, velocity => 100 },
    { time => 0.5, type => 'note_off', channel => 0, key => 60 },
    { time => 0.2, type => 'program', channel => 1, program => 48 },
    { time => 0.2, type => 'note_on', channel => 1, key => 64, velocity => 90 },
    { time => 1.0, type => 'note_off', channel => 1, key => 64 },
    { time => 0.3, type => 'note_on', channel => 9, key => 38, velocity => 110 },
    # the pedal holds a note let go, until it is lifted
    { time => 0.4, type => 'controller', channel => 2, number => 64, value => 127 },
    { time => 0.4, type => 'note_on', channel => 2, key => 67, velocity => 80 },
    { time => 0.6, type => 'note_off', channel => 2, key => 67 },
    { time => 1.5, type => 'controller', channel => 2, number => 64, value => 0 },
);
my ($rendered, $foreseen) = (rendered_ends(\@events), foreseen_ends(\@events));
is(scalar @$foreseen, scalar @$rendered, 'foresee: every voice');
my $off = 0;
for my $i (0 .. $#$rendered) {
    my $d = $rendered->[$i] - $foreseen->[$i];
    $off = abs $d if abs $d > abs $off;
}
cmp_ok($off, '>=', -0.006, 'foresee: no voice found done before its end');
cmp_ok($off, '<=', $quantum / $rate + 0.006, "foresee: each found done within the quantum after (the most $off s)");
cmp_ok($foreseen->[-1], '>', 1.5, 'foresee: the pedal held the note');

# The profile's sums.
my $profile = Peta::Synth::Profile->new(timeline => \@events, rate => $rate, partials => 16, tail => 5);
my $voices = $profile->voices;
is(scalar @$voices, 4, 'the profile: four voices');
is_deeply($profile->programs, [ 0, 48 ], 'its programs');
is_deeply($profile->drums, [38], 'its drums');
my $load = $profile->load(0.25);
my $seconds = sum0(map { $_->{end} - $_->{start} } @$voices);
cmp_ok(abs(sum0(map { $_->{voices} } @$load) * 0.25 - $seconds), '<', 1e-9, "the load adds up to the voices' seconds");
my $costs = { quantum => 0.001, voice => 0.0001, partial => 0.00001, filter => 0, copy => 0, string => 0, fm => 0, band => 0 };
my $predicted = $profile->predict($costs, 0.25);
is(scalar @$predicted, scalar @$load, 'a prediction a step');
my $quanta = $rate / Peta::Synth::Profile::QUANTUM;
my $expected = ($costs->{quantum} + $load->[2]{voices} * $costs->{voice} + $load->[2]{partials} * $costs->{partial}) * $quanta;
cmp_ok(abs($predicted->[2]{load} - $expected), '<', 1e-12, 'the prediction: the costs times what sounds');
my $notes = $profile->notes;
is(scalar @$notes, 4, 'four different notes');
is((grep { !defined $_->{program} } @$notes)[0]{key}, 38, 'the drum among them');

done_testing;

use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Patch;
use Peta::Synth::Voice;

my $rate = 48000;

# Every GM program and drum key makes a voice with partials within the budget,
# below Nyquist, with finite amplitudes.
for my $program (0 .. 127) {
    my $patch = Peta::Synth::Patch::program($program);
    for my $key (24, 60, 108) {
        my $voice = Peta::Synth::Voice->new($patch, key => $key, velocity => 100, rate => $rate, partials => 32);
        my $bad = grep { $_ * $voice->{f0} > 0.45 * $rate } @{ $voice->{ratio} };
        $bad += grep { !($_ == $_ && abs($_) < 10) } @{ $voice->{amp} };
        if ($bad || $voice->partials > 32 + 3 * 16) {
            fail("program $program key $key: $bad bad partials, " . $voice->partials . ' in all');
        }
    }
}
pass('every program makes sound voices');
for my $key (35 .. 81, 20, 100) {
    my $voice = Peta::Synth::Voice->new(Peta::Synth::Patch::drum($key), key => $key, velocity => 100, rate => $rate);
    fail("drum $key is silent") unless $voice->partials || $voice->{noise};
}
pass('every drum key makes a voice');

# The budget is kept: a piano voice has at most as many partials as asked for, unison included.
for my $budget (4, 16, 64) {
    my $voice = Peta::Synth::Voice->new(Peta::Synth::Patch::program(0), key => 40, velocity => 100, rate => $rate, partials => $budget);
    cmp_ok($voice->partials, '<=', $budget, "piano within a budget of $budget");
}

# The same seed, the same voice; a voice's partials have an RMS of 0.5 before its level.
my @twins = map { Peta::Synth::Voice->new(Peta::Synth::Patch::program(48), key => 60, velocity => 80, rate => $rate, seed => 7) } 1 .. 2;
is_deeply($twins[0]{phase}, $twins[1]{phase}, 'the same seed gives the same phases');
my $sum = 0;
$sum += $_**2 for @{ $twins[0]{amp} };
cmp_ok(abs(sqrt($sum / 2) - 0.5), '<', 1e-9, 'the partials have an RMS of 0.5');

# Controls: the envelope rises, holds, and falls after the release.
my $voice = Peta::Synth::Voice->new(Peta::Synth::Patch::program(48), key => 60, velocity => 100, rate => $rate, start => 0);
my $flat = { map { $_ => [ (0) x 1001 ] } qw(bend mod) };
$flat->{$_} = [ (1) x 1001 ] for qw(gl gr gs);
$voice->{first} = 0;
$voice->controls(0, 100, 64, $flat);
my $env = $voice->{env};
cmp_ok($env->[0], '==', 0, 'silent at the start');
cmp_ok($env->[20], '>', $env->[1], 'the attack rises');
$voice->release(64 * 100);
$voice->controls(64 * 100, 750, 64, $flat);    # a second after the release
cmp_ok($voice->{env}[750], '<', $voice->{env}[0] / 10, 'after the release it falls');
ok(!$voice->done(1), 'not done while it still sounds');
$voice->controls(64 * 100 + $rate * 10, 100, 64, $flat);
ok($voice->done(10), 'done long after the release');

# Pitch: the fundamental in radians per sample, and a bend of 12 semitones doubles it.
my $a4 = Peta::Synth::Voice->new(Peta::Synth::Patch::program(81), key => 69, velocity => 100, rate => $rate);
$a4->{first} = 0;
$a4->controls(0, 1, 64, $flat);
my $plain = $a4->{w}[0];
cmp_ok(abs($plain - 2 * 3.141592653589793 * 440 / $rate), '<', 1e-9, 'A4 is 440 Hz');
$a4->controls(0, 1, 64, { %$flat, bend => [ 12, 12 ] });
cmp_ok(abs($a4->{w}[0] / $plain - 2), '<', 1e-9, 'a bend of an octave doubles it');

# Drums ignore the key's release and ring by themselves.
my $snare = Peta::Synth::Voice->new(Peta::Synth::Patch::drum(38), key => 38, velocity => 100, rate => $rate);
$snare->release(10);
ok(!defined $snare->{released}, 'a drum ignores note off');

# The stiffness up the keyboard: with stretch_key 1, B doubles an octave up.
{
    my %patch = (%{ Peta::Synth::Patch::defaults() }, stretch => 0.001, stretch_key => 1, max => 8, cutoff => 20000);
    my %B = map {
        my $voice = Peta::Synth::Voice->new(\%patch, key => $_, velocity => 100, rate => $rate, partials => 8);
        my ($r8) = sort { $b <=> $a } @{ $voice->{ratio} };      # the eighth, the highest
        ($_ => (($r8 / 8)**2 - 1) / 64);
    } 60, 72;
    cmp_ok(abs($B{60} / 0.001 - 1), '<', 1e-9, 'stretch_key: B as stretch says at middle C');
    cmp_ok(abs($B{72} / 0.002 - 1), '<', 1e-9, 'stretch_key: twice that an octave up');
}

# Unison copies in phase with unison_sync, each its own without.
for my $sync (0, 1) {
    my %patch = (%{ Peta::Synth::Patch::defaults() }, unison => 3, detune => 10, unison_k => 4, max => 4, unison_sync => $sync);
    my $voice = Peta::Synth::Voice->new(\%patch, key => 60, velocity => 100, rate => $rate, partials => 32, seed => 3);
    my @phase = @{ $voice->{phase} };
    is(scalar @phase, 12, "unison_sync $sync: four partials, three copies");
    my $same = grep { $phase[$_] == $phase[ $_ + 4 ] && $phase[$_] == $phase[ $_ + 8 ] } 0 .. 3;
    is($same, $sync ? 4 : 0, $sync ? 'unison_sync: the copies begin in phase' : 'without: each copy its own phase');
}

# Every patch's fields within the ranges the editor gives them: a page sets
# nothing it cannot show, nor takes a patch's default back to another value.
{
    my @info    = grep { $_->{scale} ne 'choice' } @{ Peta::Synth::Patch::field_info() };
    my @patches = (
        (map { [ "program $_", Peta::Synth::Patch::program($_) ] } 0 .. 127),
        (map { [ "variation $_->[0]:$_->[1]", Peta::Synth::Patch::program($_->[1], $_->[0]) ] } @{ Peta::Synth::Patch::variations() }),
        (map { my $kit = $_; map { [ "drum $kit:$_", Peta::Synth::Patch::drum($_, $kit) ] } 27 .. 87 } sort keys %{ Peta::Synth::Patch::kits() }),
    );
    my @outside;
    for my $patch (@patches) {
        my ($what, $p) = @$patch;
        for my $field (@info) {
            my $value = $p->{ $field->{name} };
            push @outside, "$what: $field->{name} $value" if !ref $value && ($value < $field->{min} || $value > $field->{max});
        }
    }
    is_deeply(\@outside, [], "every patch's fields within the editor's ranges");
}

done_testing;

use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# Every engine renders what the Perl engine renders: to rounding in double
# precision (PDL), to what 32-bit floats hold (GPU). The GPU's FM with
# feedback drifts most, its own rounding fed back: 1.1e-4 of the peak at
# the end of the modulated take, the rest within 2e-5.
my %TOLERANCE = (pdl => 1e-9, gpu => 2e-4);    # of the peak

my $rate = 24000;

# Notes that start inside a quantum and between blocks, a bend, the
# modulation wheel, unison voices, drums with noise, notes let go and done.
my @events = (
    { time => 0,     type => 'program', channel => 1, program => 48 },
    { time => 0,     type => 'program', channel => 2, program => 81 },
    { time => 0,     type => 'program', channel => 3, program => 24 },
    { time => 0,     type => 'program', channel => 4, program => 4 },
    { time => 0.011, type => 'note_on', channel => 4, key => 64, velocity => 90 },
    { time => 0.130, type => 'pitch_bend', channel => 4, value => 2000 },
    { time => 0.020, type => 'note_on', channel => 3, key => 45, velocity => 100 },
    { time => 0.100, type => 'pitch_bend', channel => 3, value => -5000 },
    { time => 0,     type => 'note_on', channel => 0, key => 60, velocity => 100 },
    { time => 0.013, type => 'note_on', channel => 1, key => 67, velocity => 80 },
    { time => 0.031, type => 'note_on', channel => 9, key => 38, velocity => 110 },
    { time => 0.052, type => 'note_on', channel => 2, key => 72, velocity => 90 },
    { time => 0.060, type => 'note_on', channel => 9, key => 42, velocity => 90 },
    { time => 0.090, type => 'pitch_bend', channel => 1, value => 3000 },
    { time => 0.120, type => 'controller', channel => 2, number => 1, value => 100 },
    { time => 0.150, type => 'note_off', channel => 0, key => 60 },
    { time => 0.200, type => 'note_on', channel => 9, key => 36, velocity => 120 },
    { time => 0.240, type => 'note_off', channel => 1, key => 67 },
    { time => 0.300, type => 'note_off', channel => 2, key => 72 },
);

# The same notes again, the patches given filters and modulation: a
# low-pass of 24 dB swept by the second envelope and an LFO, resonant; a
# band-pass on the strings, its cutoff on the wheel; a high-pass on the
# piano; the pitch, level, pan and noise modulated; more bands of noise
# (a low-pass among them; two of four poles, one in grains), and noise on the partials; a struck, stiff
# string beside the piano's partials, a plucked one alone on a guitar,
# bent; FM alone
# (feedback, an LFO on its index) and beside the strings' partials.
my %bank = (programs => {
    0  => { filter => 'hp12', filter_cutoff => 800, filter_q => 2, mods => [ [ 'lfo2', 'pan', 0.8 ], [ 'velocity', 'level', -0.3 ] ],
            string => 0.6, string_damp => 0.4, string_decay => 1.5, string_excite => 'strike', string_stiff => 0.0008 },
    24 => { partials => [], string => 1, string_pick => 0.2, string_damp => 0.1, mods => [ [ 'lfo1', 'pitch', 0.5 ] ] },
    4  => { partials => [], fm => 1, fm_alg => 5, fm_fb => 0.6, op2_ratio => 14, op2_level => 2, op2_decay => 0.2, op2_sustain => 0,
            op3_level => 0.8, op4_level => 3, op4_ratio => 1.003, mods => [ [ 'lfo1', 'fm', 1 ] ], lfo1_rate => 6 },
    48 => { filter => 'bp', filter_cutoff => 1200, fm => 0.3, fm_alg => 1, op2_ratio => 2, op2_level => 1.5, filter_q => 3, mods => [ [ 'wheel', 'cutoff', 2 ], [ 'lfo1', 'pitch', 0.3 ] ], lfo1_shape => 'triangle',
            noise => 0.2, noise_sustain => 0.5, noise_poles => 4, noise_grains => 60,
            noise2 => 0.3, noise2_mode => 'low', noise2_center => 400, noise2_sustain => 1,
            noise3 => 0.2, noise3_mode => 'high', noise3_center => 6000, noise3_decay => 5, noise3_poles => 4, rough => 0.4, rough_rate => 80 },
    81 => { filter => 'lp24', filter_cutoff => 400, filter_q => 6, filter_env => 4, env2_attack => 0.02, env2_decay => 0.1,
            mods => [ [ 'lfo1', 'cutoff', 1 ], [ 'env2', 'noise', 1 ] ], lfo1_rate => 7, lfo1_shape => 'square' },
}, drums => { 38 => { filter => 'lp12', filter_cutoff => 300, mods => [ [ 'lfo2', 'q', 2 ] ], lfo2_shape => 'random', lfo2_rate => 30 } });

sub take ($name, $edits = undef, $waves = 1) {
    my $engine = Peta::Synth::Engine::create($name);
    my $synth = Peta::Synth::Synth->new(rate => $rate, partials => 24, engine => $engine, limiter => 0, waves => $waves);
    $synth->apply_edits($edits) if $edits;
    $synth->schedule(\@events);
    my (@left, @right);
    for (1 .. 30) {
        my ($l, $r) = $synth->render_arrays(512);
        push @left, @$l;
        push @right, @$r;
    }
    return [ @left, @right ];
}

# The plain patches with their harmonic partials read from wave sequences
# (as by default), and every partial turned one by one.
for my $case ([ 'plain', undef ], [ 'plain, every partial turned', undef, 0 ], [ 'filtered and modulated', \%bank ]) {
    my ($label, $edits, $waves) = @$case;
    $waves //= 1;
    my $reference = take('perl', $edits, $waves);
    my $peak = 0;
    for (@$reference) { $peak = abs $_ if abs $_ > $peak }
    cmp_ok($peak, '>', 0.05, "$label: the reference sounds");
    isnt(join(',', @$reference), join(',', @{ take('perl') }), "$label: other than the plain patches") if $edits;

    for my $name (sort keys %TOLERANCE) {
        SKIP: {
            skip "no $name engine here", 2 unless Peta::Synth::Engine::try($name);
            my $take = take($name, $edits, $waves);
            is(scalar @$take, scalar @$reference, "$label, $name: as many samples");
            my $worst = 0;
            for my $i (0 .. $#$reference) {
                my $d = abs($take->[$i] - $reference->[$i]);
                $worst = $d if $d > $worst;
            }
            cmp_ok($worst / $peak, '<', $TOLERANCE{$name}, "$label, $name: the same sound");
        }
    }
}

# Voices without partials only (a drum of noise alone, a string alone):
# the GPU engine renders them too.
SKIP: {
    skip 'no gpu engine here', 1 unless Peta::Synth::Engine::try('gpu');
    my @takes = map {
        my $s = Peta::Synth::Synth->new(rate => $rate, partials => 16, engine => Peta::Synth::Engine::create($_), limiter => 0);
        $s->apply_edits({ programs => { 0 => { partials => [], string => 1 } } });
        $s->play({ type => 'note_on', channel => 9, key => 69, velocity => 100 });
        $s->play({ type => 'note_on', channel => 0, key => 50, velocity => 100 });
        [ map { @{ ($s->render_arrays(512))[0] } } 1 .. 8 ];
    } 'perl', 'gpu';
    my ($worst, $peak) = (0, 0);
    for my $i (0 .. $#{ $takes[0] }) {
        my $d = abs($takes[0][$i] - $takes[1][$i]);
        $worst = $d if $d > $worst;
        $peak = abs $takes[0][$i] if abs $takes[0][$i] > $peak;
    }
    cmp_ok($worst / $peak, '<', 1e-4, 'gpu: voices without partials, the same sound');
}

# The reverb on the card (the GPU engine runs it): lines shorter than a
# quantum (several chunks), a predelay longer than one, a long tail with no
# voices; cleared; handed back to Perl and taken again; two synthesizers
# taking turns on the card. Each against the same in Perl.
SKIP: {
    skip 'no gpu engine here', 4 unless Peta::Synth::Engine::try('gpu');
    my $gpu  = Peta::Synth::Engine::create('gpu');
    my $perl = Peta::Synth::Engine::create('perl');
    my @burst = (
        { time => 0,    type => 'note_on',  channel => 0, key => 64, velocity => 120 },
        { time => 0,    type => 'note_on',  channel => 9, key => 38, velocity => 120 },
        { time => 0.08, type => 'note_off', channel => 0, key => 64 },
    );
    my $synth = sub ($engine) {
        my $s = Peta::Synth::Synth->new(rate => $rate, partials => 16, engine => $engine, limiter => 0);
        $s->reverb->set(size => 0.2)->set(predelay => 0.1)->set(time => 3);
        $s->schedule(\@burst);
        return $s;
    };
    my $apart = sub ($a, $b) {
        my ($worst, $top) = (0, 0);
        for my $i (0 .. $#$a) { my $d = abs($a->[$i] - $b->[$i]); $worst = $d if $d > $worst; $top = abs $a->[$i] if abs $a->[$i] > $top }
        return $top ? $worst / $top : 1;
    };
    # $plan->($quantum, $synth) may change the synthesizer before a quantum.
    my $run = sub ($engine, $plan = undef) {
        my $s = $synth->($engine);
        my @out;
        for my $q (0 .. 59) { $plan->($q, $s) if $plan; push @out, map { @$_ } $s->render_arrays(512) }
        return \@out;
    };
    my $reference = $run->($perl);
    cmp_ok($apart->($reference, $run->($gpu)), '<', 1e-4, 'the reverb on the card: lines shorter than a quantum, a long predelay, a tail without voices');
    my $clear = sub ($q, $s) { $s->reverb->clear if $q == 30 };
    cmp_ok($apart->($run->($perl, $clear), $run->($gpu, $clear)), '<', 1e-4, 'cleared, as in Perl');
    my $switch = sub ($q, $s) { $s->{engine} = $perl if $q == 20; $s->{engine} = $gpu if $q == 40 };
    cmp_ok($apart->($reference, $run->($gpu, $switch)), '<', 1e-4, 'handed back to Perl and taken again, the tail goes on');
    my ($one, $two) = ($synth->($gpu), $synth->($gpu));
    my (@one, @two);
    for (0 .. 59) { push @one, map { @$_ } $one->render_arrays(512); push @two, map { @$_ } $two->render_arrays(512) }
    cmp_ok($apart->($reference, \@one) + $apart->($reference, \@two), '<', 2e-4, 'two synthesizers taking turns on the card');
}

# 'auto' takes the fastest measured, or what the environment says.
my @measured = Peta::Synth::Engine::measure(rate => $rate, partials => 8);
is_deeply([ sort map { $_->{name} } @measured ], [ sort(Peta::Synth::Engine::available()) ], 'every engine here is measured');
ok(!(grep { $_->{speed} <= 0 } @measured), 'and has a speed');
{
    local $ENV{PETA_SYNTH_ENGINE} = 'perl';
    is(Peta::Synth::Engine::create('auto')->name, 'perl', 'PETA_SYNTH_ENGINE decides for auto');
}

done_testing;

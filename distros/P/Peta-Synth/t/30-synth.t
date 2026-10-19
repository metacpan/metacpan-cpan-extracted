use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

my $rate = 24000;    # small and fast: the tests are about behaviour
my $engine = Peta::Synth::Engine::create('perl');
sub synth (%arg) { return Peta::Synth::Synth->new(rate => $rate, partials => 12, engine => $engine, %arg) }

sub peak ($left, $right) {
    my $peak = 0;
    for (@$left, @$right) { $peak = abs $_ if abs $_ > $peak }
    return $peak;
}

sub rms ($samples) {
    my $sum = 0;
    $sum += $_**2 for @$samples;
    return sqrt($sum / @$samples);
}

# Silence without notes; sound with one; the same sound every time.
my $s = synth();
my ($l, $r) = $s->render_arrays(1024);
is(peak($l, $r), 0, 'no notes, no sound');

my @takes = map {
    my $one = synth();
    $one->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
    [ $one->render_arrays(4096) ];
} 1 .. 2;
cmp_ok(peak(@{ $takes[0] }), '>', 0.01, 'a note sounds');
is_deeply($takes[0], $takes[1], 'the same notes, the same samples');

# Panned hard left, the right channel is silent.
$s = synth();
$s->play({ type => 'controller', channel => 0, number => 10, value => 0 });
$s->play({ type => 'controller', channel => 0, number => 91, value => 0 });
$s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
($l, $r) = $s->render_arrays(2048);
cmp_ok(rms($r), '<', 1e-9, 'hard left: nothing on the right');
cmp_ok(rms($l), '>', 0.001, 'hard left: sound on the left');

# A note off releases; the voice goes once it is silent.
$s = synth();
$s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
$s->render_arrays(1024);
$s->play({ type => 'note_off', channel => 0, key => 60 });
$s->render_arrays(1024) for 1 .. 60;
is($s->active, 0, 'a released note ends');

# The sustain pedal holds a released note until it is let go.
$s = synth();
$s->play({ type => 'controller', channel => 0, number => 64, value => 127 });
$s->play({ type => 'note_on', channel => 0, key => 64, velocity => 100 });
$s->render_arrays(1024);
$s->play({ type => 'note_off', channel => 0, key => 64 });
$s->render_arrays(1024) for 1 .. 20;
my ($voice) = @{ $s->{active} };
ok($voice && !defined $voice->{released}, 'the pedal holds the note');
$s->play({ type => 'controller', channel => 0, number => 64, value => 0 });
$s->render_arrays(1024);
ok(defined $voice->{released}, 'letting go of the pedal releases it');

# Drums ring past note off; voices beyond the limit are stolen.
$s = synth();
$s->play({ type => 'note_on', channel => 9, key => 38, velocity => 100 });
$s->play({ type => 'note_off', channel => 9, key => 38 });
$s->render_arrays(1024);
is($s->active, 1, 'a drum rings after note off');

$s = synth(voices => 4);
$s->play({ type => 'note_on', channel => 0, key => 60 + $_, velocity => 100 }) for 0 .. 7;
my $killed = grep { defined $_->{killed} } @{ $s->{active} };
is($killed, 4, 'four voices over the limit are ended');

# Scheduled events take effect at their time.
$s = synth();
$s->schedule([ { time => 0.05, type => 'note_on', channel => 0, key => 72, velocity => 100 } ]);
($l, $r) = $s->render_arrays(1024);     # 1024 samples at 24 kHz: 43 ms
is(peak($l, $r), 0, 'nothing before the scheduled note');
($l, $r) = $s->render_arrays(1024);
cmp_ok(peak($l, $r), '>', 0.001, 'the scheduled note sounds at its time');

# A patch changed while the synth runs changes the next notes.
$s = synth();
$s->program_patch(0)->{level} = 0;
$s->play({ type => 'controller', channel => 0, number => 91, value => 0 });
$s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
($l, $r) = $s->render_arrays(1024);
is(peak($l, $r), 0, 'a patch at level 0 is silent');
is(Peta::Synth::Synth->new(rate => $rate, engine => $engine)->program_patch(0)->{level}, 0.9, 'other synths keep the default');

# Chorus (CC93): the next notes in detuned copies.
{
    my @voices = map {
        my $c = synth(partials => 48);
        $c->play({ type => 'program', channel => 0, program => 16 });    # an organ: no unison of its own
        $c->play({ type => 'controller', channel => 0, number => 93, value => $_ });
        $c->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 })->{active}[0];
    } 0, 127;
    my $copies = sub ($v) { scalar grep { abs($_ / $v->{ratio}[0] - 1) < 0.02 } @{ $v->{ratio} } };
    is($copies->($voices[0]), 1, 'without chorus, each partial once');
    cmp_ok($copies->($voices[1]), '>=', 3, 'with it, in three copies');
    my ($lo, $hi) = (9, 0);
    for my $r (grep { abs($_ / $voices[1]{ratio}[0] - 1) < 0.02 } @{ $voices[1]{ratio} }) { $lo = $r if $r < $lo; $hi = $r if $r > $hi }
    cmp_ok(abs(1200 * log($hi / $lo) / log(2) - 24), '<', 0.5, 'spread 24 cents at full chorus');
}

# Lists in the bank: an electric piano (its own partials) back to the series.
{
    my $s = synth();
    $s->program_patch(4)->{partials} = undef;
    $s->program_patch(0)->{formants} = [ [ 700, 3, 0.4 ] ];
    my $bank = $s->edits;
    ok(exists $bank->{programs}{4}{partials} && !defined $bank->{programs}{4}{partials}, 'no own partials is saved as none');
    is_deeply($bank->{programs}{0}{formants}, [ [ 700, 3, 0.4 ] ], 'formants as they are');
    my $again = synth();
    $again->apply_edits($bank);
    ok(!defined $again->program_patch(4)->{partials}, 'and both come back');
    is_deeply($again->program_patch(0)->{formants}, [ [ 700, 3, 0.4 ] ], 'formants too');
}

# The reverb is quiet once nothing is on its way through it and its tail has
# died away; while nothing sounds and it is quiet, it rests.
{
    require Peta::Synth::Reverb;
    my $reverb = Peta::Synth::Reverb->new(rate => $rate);
    my @click  = (0.0) x 256;    # shorter than the predelay
    $click[0] = 1.0;
    ok($reverb->quiet, 'a new reverb is quiet');
    $reverb->process(\@click);
    ok(!$reverb->quiet, 'a click on its way through: not quiet, though nothing has come out yet');
    my $quanta = 0;
    $reverb->process([ (0.0) x 256 ]) while !$reverb->quiet && ++$quanta < 1000;
    cmp_ok($quanta * 256 / $rate, '>', 2, 'quiet only after the tail (2.2 s for 60 dB)');

    my $s    = synth();
    my $runs = 0;
    my $process = \&Peta::Synth::Reverb::process;
    no warnings 'redefine';
    local *Peta::Synth::Reverb::process = sub { $runs++; goto &$process };
    is(peak($s->render_arrays(512)), 0, 'nothing sounds: silence');
    is($runs, 0, 'and the reverb rests');
    $s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
    $s->render_arrays(512) for 1 .. 4;
    is($runs, 4, 'a note: it runs');
    $s->play({ type => 'note_off', channel => 0, key => 60, velocity => 64 });
    $quanta = 0;
    $s->render_arrays(512) while $s->busy && ++$quanta < 1000;
    ok(!$s->busy, 'the note and its tail die away');
    $runs = 0;
    $s->render_arrays(512) for 1 .. 4;
    is($runs, 0, 'and it rests again');

    # A note sounding, sent nowhere: the reverb rests; sent, it runs.
    $s->play({ type => 'controller', channel => 0, number => 91, value => 0 });
    $s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
    $s->render_arrays(512) for 1 .. 4;
    is($runs, 0, 'a note with no reverb send: the reverb rests');
    $s->play({ type => 'controller', channel => 0, number => 91, value => 40 });
    $s->render_arrays(512) for 1 .. 4;
    is($runs, 4, 'sent to it: it runs');
}

# A file from a point in it: the channels set up as it has them there, its
# notes from there on.
{
    my $s = synth();
    $s->channel(2)->{mute} = 1;
    $s->play({ type => 'controller', channel => 0, number => 7, value => 20 });
    $s->reset_channels;
    is($s->channel(0)->{volume}, 100, 'the channels reset');
    is($s->channel(2)->{mute}, 1, 'the mutes kept');

    my @file = (
        { time => 0,   type => 'program',    channel => 0, program => 40 },
        { time => 0.5, type => 'note_on',    channel => 0, key => 60, velocity => 100 },
        { time => 1,   type => 'controller', channel => 0, number => 7, value => 50 },
        { time => 1.2, type => 'note_off',   channel => 0, key => 60 },
        { time => 2,   type => 'note_on',    channel => 0, key => 62, velocity => 100 },
    );
    $s->schedule(\@file, 0.1, 1.5);
    my @at = map { [ ($_->[0] - $s->now) / $rate, $_->[1]{type}, $_->[1]{key} // '' ] } @{ $s->{queue} };
    is_deeply(\@at, [ [ 0.1, 'program', '' ], [ 0.1, 'controller', '' ], [ 0.6, 'note_on', 62 ] ],
        'from 1.5 s: what sets the channel up at once, the notes before left out');
    $s->render_arrays(4800);
    is($s->channel(0)->{program}, 40, 'the program as there');
    is($s->channel(0)->{volume},  50, 'the volume as there');
}

# Fidelity: a voice that fades ends sooner at mid, sooner still at low; a
# held one does not; low plays at most 48 voices at once.
{
    eval { synth(fidelity => 'ultra') };
    like($@, qr/no fidelity 'ultra'/, 'an unknown fidelity dies');
    eval { synth()->set(fidelity => 'ultra') };
    like($@, qr/no fidelity 'ultra'/, 'and cannot be set');

    my $lasts = sub ($fidelity, $program) {
        my $s = synth(fidelity => $fidelity);
        $s->play({ type => 'program', channel => 0, program => $program });
        $s->play({ type => 'note_on', channel => 0, key => 72, velocity => 100 });
        my $quanta = 0;
        $s->render_arrays(512), $quanta++ while $s->active && $quanta < 30 * $rate / 512;
        return $quanta * 512 / $rate;
    };
    my %bell = map { $_ => $lasts->($_, 14) } qw(high mid low);    # tubular bells, the key held
    ok($bell{high} > $bell{mid} && $bell{mid} > $bell{low}, "a bell's held note ends sooner: high $bell{high} s, mid $bell{mid} s, low $bell{low} s");
    cmp_ok($lasts->('low', 16), '>=', 30, 'an organ held sounds on at low');

    my $s = synth(fidelity => 'low');
    $s->play({ type => 'program', channel => 0, program => 16 });
    $s->play({ type => 'note_on', channel => 0, key => $_, velocity => 100 }) for 30 .. 89;
    is(scalar(grep { !defined $_->{killed} } @{ $s->{active} }), 48, 'low: 48 voices at once');
}

# The limiter: no sample over 0.98, however loud, the gain down before a
# peak comes (the sound a block, 64 samples, late); under the limit, the
# sound as it is.
{
    my $loud = synth(gain => 2);
    $loud->eq->set(low => { gain => 12 });
    $loud->play({ type => 'note_on', channel => 0, key => $_, velocity => 127 }) for 36, 40, 43, 48, 52, 55, 60;
    my $top = 0;
    for (1 .. 40) { for my $ch ($loud->render_arrays(512)) { for (@$ch) { $top = abs if abs > $top } } }
    cmp_ok($top, '<=', 0.98 + 1e-9, "loud, boosted: the highest sample $top");

    my ($on, $off) = map { synth(limiter => $_) } 1, 0;
    $_->play({ type => 'note_on', channel => 0, key => 60, velocity => 60 }) for $on, $off;
    my (@on, @off);
    for (1 .. 4) { push @on, @{ ($on->render_arrays(512))[0] }; push @off, @{ ($off->render_arrays(512))[0] } }
    is_deeply([ @on[ 64 .. $#on ] ], [ @off[ 0 .. $#off - 64 ] ], 'under the limit: the sound as it is, a block late');
}

done_testing;

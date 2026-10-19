use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Analysis;
use Peta::Synth::Engine::Perl;
use Peta::Synth::FFT;
use Peta::Synth::Patch;
use Peta::Synth::Synth;
use Peta::Synth::Voice;
use Peta::Synth::Wavetable;

use constant PI => 3.141592653589793;
my $rate = 48000;

# Harmonics, copy by copy: a unison's detuned copies; not a stiff string's
# partials, nor a bell's.
{
    my $cents = sub ($c) { 2**($c / 1200) };
    my @ratio = ((map { $_ * $cents->(-5) } 1 .. 6), map { $_ * $cents->(5) } 1 .. 3);
    my $copies = Peta::Synth::Wavetable::harmonics(\@ratio, [ (1) x 9 ], [ (0) x 9 ], [ (0) x 9 ], 2);
    is(scalar @$copies, 2, 'two copies');
    is_deeply([ map { scalar @{ $_->[1] } } @$copies ], [ 6, 3 ], 'six harmonics and three');
    is_deeply([ map { $_->[0] } @{ $copies->[1][1] } ], [ 1, 2, 3 ], 'their numbers');
    ok(!Peta::Synth::Wavetable::harmonics(\@ratio, [ (1) x 9 ], [ (0) x 9 ], [ (0) x 9 ], 1), 'not with one copy');
    my @stiff = map { $_ * sqrt(1 + 0.0004 * $_ * $_) } 1 .. 12;
    ok(!Peta::Synth::Wavetable::harmonics(\@stiff, [ (1) x 12 ], [ (0) x 12 ], [ (0) x 12 ], 2), 'not a stiff string');
    ok(!Peta::Synth::Wavetable::harmonics([ 1, 2.76, 5.4 ], [ 1, 1, 1 ], [ 0, 0, 0 ], [ 0, 0, 0 ], 3), 'not a bell');
}

# A table holds its partials: each at its level.
my $store = Peta::Synth::Wavetable->new;
{
    my @partials = map { [ $_, 0.5 / $_, 0, 0 ] } 1, 2, 3, 5, 8;
    my $sequence = $store->sequence(\@partials);
    is(scalar @{ $sequence->{tables} }, 1, 'still partials: one table');
    my $size = $sequence->{size};
    cmp_ok($size, '>=', 32 * 8, 'at least 32 samples a period of the highest');
    my @table = @{ $sequence->{tables}[0] };
    is($table[$size], $table[0], 'the last sample the first again');
    my @re = @table[ 0 .. $size - 1 ];
    my @im = (0.0) x $size;
    Peta::Synth::FFT::fft(\@re, \@im);
    my $worst = 0;
    my %level = map { $_->[0] => $_->[1] } @partials;
    for my $h (1 .. $size / 2 - 1) {
        my $a = 2 * sqrt($re[$h]**2 + $im[$h]**2) / $size;
        my $d = abs($a - ($level{$h} // 0));
        $worst = $d if $d > $worst;
    }
    cmp_ok($worst, '<', 1e-9, 'each harmonic at its level, nothing else');
    is($store->sequence([ map { [@$_] } @partials ]), $sequence, 'the same partials: the same sequence');
    is_deeply([ @{ $store->stats }{qw(made used)} ], [ 1, 2 ], 'made once, used twice');
}

# Decaying and fading in: a table wherever some partial has moved 3 dB.
{
    my @partials = ([ 1, 1, 0.5, 0 ], [ 2, 0.5, 2, 0 ], [ 3, 0.3, 6, 0.02 ]);
    my $sequence = $store->sequence(\@partials);
    my @times = @{ $sequence->{times} };
    cmp_ok(scalar @times, '>', 5, 'tables along the decay (' . @times . ')');
    my $worst = 0;
    for my $i (1 .. $#times) {
        for my $p (@partials) {
            my ($h, $a, $d, $att) = @$p;
            my $level = sub ($t) { $a * exp(-$d * $t) * ($att ? 1 - exp(-$t / $att) : 1) };
            my ($l0, $l1) = ($level->($times[ $i - 1 ]), $level->($times[$i]));
            next if $l0 < 1e-3 || $l1 < 1e-3 || $times[$i] - $times[ $i - 1 ] <= 0.002 + 1e-12;
            my $moved = abs(20 * log($l1 / $l0) / log(10));
            $worst = $moved if $moved > $worst;
        }
    }
    cmp_ok($worst, '<=', 3.05, "no partial moves more than 3 dB from one table to the next ($worst)");
}

# Which voices read tables: harmonic ones; not under a moving filter, not stiff.
{
    my $voice = sub ($patch) { Peta::Synth::Voice->new($patch, key => 60, velocity => 100, rate => $rate, partials => 32, waves => $store) };
    my %plain = (%{ Peta::Synth::Patch::defaults() }, unison => 3, detune => 10, unison_k => 8);
    is(scalar @{ $voice->({%plain})->{wave} // [] }, 3, 'a unison of three: three copies read');
    ok(!$voice->({ %plain, filter => 'lp12' })->{wave}, 'not under a moving filter');
    ok(!$voice->({ %plain, stretch => 0.0004 })->{wave}, 'not a stiff string');
}

# A voice read from tables sounds as its partials do: each partial's level,
# measured over two seconds, within 0.3 dB (one copy: no beating to blur it).
for my $case ([ 81, 'saw lead' ], [ 56, 'trumpet (its partials fade in one after another)' ], [ 32, 'acoustic bass (decaying)' ]) {
    my ($program, $name) = @$case;
    my %level;
    for my $waves (0, 1) {
        my $synth = Peta::Synth::Synth->new(rate => $rate, engine => Peta::Synth::Engine::Perl->new, waves => $waves, gain => 1, limiter => 0);
        $synth->schedule([
            { time => 0, type => 'controller', channel => 0, number => 91, value => 0 },
            { time => 0, type => 'program', channel => 0, program => $program },
            { time => 0, type => 'note_on', channel => 0, key => 48, velocity => 100 },
            { time => 1.5, type => 'note_off', channel => 0, key => 48 },
        ]);
        my $x = Peta::Synth::Analysis::mono($synth->render_frames(2 * $rate));
        $level{$waves} = Peta::Synth::Analysis::partials($x, rate => $rate, f0 => 130.81, count => 12, times => [ 0.02, 0.1, 0.4, 1.0, 1.6 ]);
    }
    my $top = $level{0}{level}[1][0];
    my $worst = 0;
    for my $k (1 .. 12) {
        for my $t (0 .. 4) {
            my ($a, $b) = ($level{0}{level}[$k][$t], $level{1}{level}[$k][$t]);
            next if $a < $top - 60;
            $worst = abs($a - $b) if abs($a - $b) > $worst;
        }
    }
    cmp_ok($worst, '<', 0.3, "$name: from tables as from partials (the most $worst dB)");
}

done_testing;

use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::EQ;
use Peta::Synth::Synth;
use Peta::Synth::Engine;

use constant PI => 3.141592653589793;

my $rate = 48000;

# The response: what each band does where it should.
my $eq = Peta::Synth::EQ->new(rate => $rate);
ok(!$eq->active, 'at first, flat');
$eq->set(low => { gain => 6 });
cmp_ok(abs($eq->response(25) - 6), '<', 0.3, 'a low shelf of +6 dB: +6 dB far below it');
cmp_ok(abs($eq->response(5000)), '<', 0.1, 'and nothing far above');
$eq->set(low => { gain => 0 }, mid2 => { gain => -9, freq => 3000, q => 2 });
cmp_ok(abs($eq->response(3000) + 9), '<', 0.05, 'a peak of -9 dB at 3 kHz: -9 dB there');
cmp_ok(abs($eq->response(300)), '<', 0.2, 'and little a decade away');
$eq->set(mid2 => { gain => 99 });
is($eq->params->{mid2}{gain}, 12, 'gains are held within -12 .. 12 dB');

# The filters do what the response says: a sine's level through them.
$eq = Peta::Synth::EQ->new(rate => $rate, bands => { mid1 => { gain => 8, freq => 1000, q => 1.5 }, high => { gain => -4 } });
for my $f (300, 1000, 12000) {
    my @x = map { sin(2 * PI * $f * $_ / $rate) } 0 .. $rate / 2 - 1;
    my ($l) = $eq->process(\@x, \@x);
    my ($in, $out) = (0, 0);
    for my $i ($rate / 4 .. $#x) { $in += $x[$i]**2; $out += $l->[$i]**2 }
    my $db = 10 * log($out / $in) / log(10);
    cmp_ok(abs($db - $eq->response($f)), '<', 0.1, sprintf('a sine at %d Hz comes out as the response says (%.1f dB)', $f, $db));
}

# In the synthesizer: flat, the sound is what it was without it; set, it
# is saved with the bank and comes back from it.
my $engine = Peta::Synth::Engine::create('perl');
my @takes = map {
    my $s = Peta::Synth::Synth->new(rate => 24000, partials => 8, engine => $engine);
    $s->eq->set(low => { gain => 3 }) if $_;
    $s->play({ type => 'note_on', channel => 0, key => 48, velocity => 100 });
    [ $s->render_arrays(2048) ];
} 0, 1;
my $flat = Peta::Synth::Synth->new(rate => 24000, partials => 8, engine => $engine);
$flat->eq->set(low => { gain => 3 })->set(low => { gain => 0 });
$flat->play({ type => 'note_on', channel => 0, key => 48, velocity => 100 });
is_deeply([ $flat->render_arrays(2048) ], $takes[0], 'a flat equalizer changes nothing');
ok(!eq_array($takes[0][0], $takes[1][0]), 'a set one changes the sound');

my $s = Peta::Synth::Synth->new(rate => 24000, engine => $engine);
$s->eq->set(high => { gain => -3, freq => 6000 });
$s->reverb->set(time => 4.5);
my $bank = $s->edits;
is($bank->{master}{eq}{high}{gain}, -3, 'the bank holds the equalizer');
is($bank->{master}{reverb}{time}, 4.5, 'and the reverb');
ok(!exists Peta::Synth::Synth->new(rate => 24000, engine => $engine)->edits->{master}, 'a synthesizer as it starts has nothing to save');
my $again = Peta::Synth::Synth->new(rate => 24000, engine => $engine);
$again->apply_edits($bank);
is_deeply($again->eq->params, $s->eq->params, 'and gives it back');
is($again->reverb->params->{time}, 4.5, 'reverb too');

# A channel's equalizer: gains on its voices' partials, at once.
my $ch = Peta::Synth::Synth->new(rate => 48000, partials => 32, engine => $engine);
$ch->set_channel_eq(2, low => { gain => 12, freq => 200 });
my $v = $ch->play({ type => 'note_on', channel => 2, key => 36, velocity => 100 })->{active}[0];
my $low = $v->{amp}[0] / $v->{amp0}[0];
cmp_ok(abs(20 * log($low) / log(10) - $ch->channel_eq(2)->response($v->{f0} * $v->{ratio}[0])), '<', 1e-9, 'a low partial gains what the shelf says');
cmp_ok($low, '>', 2, 'much, at 65 Hz');
my ($top) = sort { $v->{ratio}[$b] <=> $v->{ratio}[$a] } 0 .. $#{ $v->{ratio} };    # the highest partial
cmp_ok(abs($v->{amp}[$top] / $v->{amp0}[$top] - 1), '<', 0.05, 'a high one hardly');
$v->{gpu_parts} = 'cached';
$ch->set_channel_eq(2, low => { gain => 0 });
is_deeply($v->{amp}, $v->{amp0}, 'flat again: the sounding note as it was made');
ok(!exists $v->{gpu_parts}, 'and what an engine kept of it is let go');
my $other = $ch->play({ type => 'note_on', channel => 3, key => 36, velocity => 100 })->{active}[-1];
$ch->set_channel_eq(2, high => { gain => -6 });
ok(!exists $other->{amp0}, "another channel's voices are left alone");

# What changes nothing does nothing: a flat equalizer on a voice never
# equalized, a band at 0 dB moved while another works.
my $plain = $ch->play({ type => 'note_on', channel => 4, key => 48, velocity => 100 })->{active}[-1];
$plain->{gpu_parts} = 'cached';
$ch->set_channel_eq(4, low => { freq => 300 });
ok(!exists $plain->{amp0} && exists $plain->{gpu_parts}, 'a flat equalizer: the voice left as it is');
$ch->set_channel_eq(4, mid1 => { gain => 6 });
my $amp = $plain->{amp};
$plain->{gpu_parts} = 'cached';
$ch->set_channel_eq(4, low => { freq => 150 });
ok($plain->{amp} == $amp && exists $plain->{gpu_parts}, 'a band at 0 dB moved: nothing made again');
$ch->set_channel_eq(4, mid1 => { freq => 800 });
ok($plain->{amp} != $amp && !exists $plain->{gpu_parts}, 'a band that works, moved: made again');

$ch->reset;
is($ch->channel_eq(2)->params->{high}{gain}, -6, "a reset leaves the channels' equalizers");
my $cbank = $ch->edits;
is($cbank->{master}{channels}{2}{high}{gain}, -6, 'the bank holds them');
my $back = Peta::Synth::Synth->new(rate => 48000, engine => $engine);
$back->apply_edits($cbank);
is_deeply($back->channel_eq(2)->params, $ch->channel_eq(2)->params, 'and gives them back');

done_testing;

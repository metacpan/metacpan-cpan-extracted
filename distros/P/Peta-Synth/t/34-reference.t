use v5.36;
use Test::More;
use lib 'lib', 't/lib';
use Peta::Synth::Engine;
use AudioReference;

# Every instrument sounds as its reference in t/audio-reference does, on
# every engine there is here: the difference at least 60 dB under the sound.
# PDL renders what the Perl engine does, the GPU (32-bit floats) differs by
# 76 dB at most; a change of the level by 0.1 dB is 39 dB. A patch changed
# on purpose has its reference written anew (devbin/audio-reference).

my $SNR = 60;

my @items = AudioReference::items();
my @files = glob "$AudioReference::DIR/*.wav";
is(scalar @files, scalar @items, 'a reference for each instrument, and no other');

for my $name (Peta::Synth::Engine::available()) {
    my $engine = Peta::Synth::Engine::create($name, rate => $AudioReference::RATE);
    for my $item (@items) {
        my $file = "$AudioReference::DIR/$item->[0]";
        if (!-e $file) {
            fail("$name: $item->[0]: no reference");
            next;
        }
        my $c = AudioReference::compare(AudioReference::read_wav($file), AudioReference::render($engine, $item));
        ok($c->{snr} eq 'inf' || $c->{snr} >= $SNR, "$name: $item->[0]")
            or diag(sprintf 'snr %.1f dB; level %+.1f dB; differs most at %.2f s (%+.1f dB)', @$c{qw(snr level at frame)});
    }
}

done_testing;

use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::Synth;
use Peta::Synth::MIDI;

my $dir = tempdir(CLEANUP => 1);

# A short piece: a chord, a bass line, a few drums.
my @track;
for my $beat (0 .. 3) {
    my $t = $beat * 240;
    push @track, { tick => $t, type => 'note_on', channel => 1, key => 36 + 2 * $beat, velocity => 100 },
                 { tick => $t + 200, type => 'note_off', channel => 1, key => 36 + 2 * $beat };
    push @track, { tick => $t, type => 'note_on', channel => 9, key => $beat % 2 ? 38 : 36, velocity => 110 };
}
push @track, map { ({ tick => 0, type => 'note_on', channel => 0, key => $_, velocity => 80 },
                    { tick => 900, type => 'note_off', channel => 0, key => $_ }) } 60, 64, 67;
my $midi = Peta::Synth::MIDI->new(division => 480, tracks => [ \@track ]);

my %opt = (rate => 16000, partials => 8, engine => 'perl', normalize => undef, bits => 32, tail => 2);
my $one = Peta::Synth->render_file($midi, "$dir/one.wav", %opt, workers => 1);
my $two = Peta::Synth->render_file($midi, "$dir/two.wav", %opt, workers => 2);

is($one->{notes}, 11, 'every note is played');
is($two->{notes}, 11, 'every note is played by one of two workers');

sub samples ($file) {
    open my $fh, '<:raw', $file or die;
    local $/;
    return [ unpack 'f<*', substr(<$fh>, 44) ];
}
my ($a, $b) = (samples("$dir/one.wav"), samples("$dir/two.wav"));
my $peak = 0;
$peak = abs $_ > $peak ? abs $_ : $peak for @$a;
cmp_ok($peak, '>', 0.01, 'the piece sounds');
my $diff = 0;
for my $i (0 .. ($#$a < $#$b ? $#$a : $#$b)) {
    my $d = abs($a->[$i] - $b->[$i]);
    $diff = $d if $d > $diff;
}
cmp_ok($diff, '<', 1e-5, 'two workers give the sound one gives (the reverb is linear)');

my $normal = Peta::Synth->render_file($midi, "$dir/n.wav", %opt, normalize => -6);
my $loudest = 0;
$loudest = abs $_ > $loudest ? abs $_ : $loudest for @{ samples("$dir/n.wav") };
cmp_ok(abs($loudest - 10**(-6 / 20)), '<', 1e-4, 'normalized to -6 dBFS');

my $cut = Peta::Synth->render_file($midi, "$dir/c.wav", %opt, length => 0.5);
cmp_ok($cut->{notes}, '<', 11, 'a length plays only the start');

done_testing;

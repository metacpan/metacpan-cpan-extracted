use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Output::PipeWire;

# The stream's format, as the SPA POD PipeWire reads: an Object (type 15)
# of type Format (0x40003), id EnumFormat (3), its properties each a key,
# flags and a POD, everything in 8-byte steps.
my $pod = Peta::Synth::Output::PipeWire::_format(44100);
is(length($pod) % 8, 0, 'the POD is whole 8-byte steps');
my ($size, $type, $object, $id) = unpack 'L< L< L< L<', $pod;
is($size + 8, length $pod, 'its size is its body');
is($type, 15, 'an Object');
is(sprintf('0x%x', $object), '0x40003', 'of type Format');
is($id, 3, 'for EnumFormat');
my %props;
my $at = 16;
while ($at < length $pod) {
    my ($key, $flags, $bytes, $kind) = unpack 'L< L< L< L<', substr $pod, $at, 16;
    $props{$key} = [ $kind, substr $pod, $at + 16, $bytes ];
    $at += 16 + $bytes + (8 - $bytes % 8) % 8;
}
is($at, length $pod, 'the properties fill it');
is_deeply([ sort { $a <=> $b } keys %props ], [ 1, 2, 0x10001, 0x10003, 0x10004, 0x10005 ],
    'media type, subtype, format, rate, channels, positions');
is(unpack('L<', $props{0x10001}[1]), 0x11B, 'the format F32LE');
is(unpack('l<', $props{0x10003}[1]), 44100, 'the rate');
is(unpack('l<', $props{0x10004}[1]), 2, 'two channels');
is_deeply([ unpack 'L< L< L< L<', $props{0x10005}[1] ], [ 4, 3, 3, 4 ], 'an array of ids: front left, front right');

# Only pperl has the FFI.
if ($^V !~ /\.99\z/) {
    ok(!Peta::Synth::Output::PipeWire::available(), 'perl5: not available, and says why') and like($@, qr/\S/, 'a reason');
}

# Playing to the real PipeWire only when asked to: half a second of silence.
SKIP: {
    skip 'PETA_SYNTH_LIVE is not set: the sound server is not touched', 2 unless $ENV{PETA_SYNTH_LIVE};
    skip "no PipeWire from here: $@", 2 unless Peta::Synth::Output::PipeWire::available();
    my $out = Peta::Synth::Output::PipeWire->new(rate => 48000, latency => 0.05, title => 'Peta::Synth test (silence)');
    $out->write([ (0.0) x 1200 ], [ (0.0) x 1200 ]) for 1 .. 20;
    $out->close;
    pass('a stream made, written and closed');
    cmp_ok($out->sent, '>=', 0.4, 'the silence was taken');
}

done_testing;

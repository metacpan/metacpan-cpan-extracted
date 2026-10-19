use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::MIDI::Stream;
use Peta::Synth::Input;

# Bytes as a device sends them.
my $stream = Peta::Synth::MIDI::Stream->new;
my @events = $stream->feed("\x90\x3c\x64\x40\x50");    # a note on, then one by running status
is_deeply([ map { [ @$_{qw(type key velocity)} ] } @events ], [ [ 'note_on', 60, 100 ], [ 'note_on', 64, 80 ] ], 'running status');
@events = $stream->feed("\xb0\x07");
is(scalar @events, 0, 'a message cut short waits ...');
@events = $stream->feed("\xf8\x50");                    # the clock between its bytes
is_deeply($events[0], { type => 'controller', channel => 0, number => 7, value => 80 }, '... for its last byte, clock or not');
@events = $stream->feed("\xf0\x7e\x7f\x09");
is(scalar @events, 0, 'system exclusive in pieces ...');
@events = $stream->feed("\x01\xf7\xc1\x05");
is_deeply(\@events, [ { type => 'sysex', data => "\x7e\x7f\x09\x01\xf7" }, { type => 'program', channel => 1, program => 5 } ],
    '... whole at F7, and what follows');
@events = $stream->feed("\xf2\x01\x02\x03");             # song position, then a data byte without a status
is(scalar @events, 0, 'system common skipped, and running status cancelled');

# The ALSA sequencer: a second client sends to the port.
SKIP: {
    my $in = eval { Peta::Synth::Input->open('none') };
    skip "no ALSA sequencer here: $@", 10 unless $in;
    like($in->address, qr/\A\d+:\d+\z/, 'a port: ' . $in->address);
    ok(scalar(grep { $_->{client} =~ /System/ } $in->sources) == 0, 'sources: not the system');

    open my $seq, '+<:raw', '/dev/snd/seq' or die;
    my ($c, $p) = split /:/, $in->address;
    my $event = sub ($type, $data, $extra = undef) {
        my $flags = defined $extra ? 1 << 2 : 0;
        $data = pack('V Q', length $extra, 0) if defined $extra;
        syswrite $seq, pack('C C c C x8 C C C C a12', $type, $flags, 0, 253, 0, 0, $c, $p, $data) . ($extra // '');
    };
    $event->(6, pack 'C C C C I', 2, 60, 100, 0, 0);     # note on
    $event->(6, pack 'C C C C I', 2, 62, 0, 0, 0);       # note on, velocity 0
    $event->(7, pack 'C C C C I', 2, 60, 30, 0, 0);      # note off, its velocity
    $event->(10, pack 'C x3 I i', 3, 7, 90);             # controller
    $event->(13, pack 'C x3 I i', 3, 0, -4096);          # bend
    $event->(14, pack 'C x3 I i', 3, 1, 1000);           # 14-bit modulation
    $event->(16, pack 'C x3 I i', 3, 0, 12 << 7);        # RPN 0: 12 semitones
    $event->(130, '', "\xf0\x7f\x7f\x04");               # system exclusive, in two pieces
    $event->(130, '', "\x01\x00\x40\xf7");
    my @got = $in->events(1);
    for (1 .. 10) { last if @got >= 12; push @got, $in->events(0.1) }
    is_deeply($got[0], { type => 'note_on', channel => 2, key => 60, velocity => 100 }, 'a note on');
    is_deeply($got[1], { type => 'note_off', channel => 2, key => 62, velocity => 64 }, 'velocity 0: a note off');
    is_deeply($got[2], { type => 'note_off', channel => 2, key => 60, velocity => 30 }, 'a note off, with its velocity');
    is_deeply($got[3], { type => 'controller', channel => 3, number => 7, value => 90 }, 'a controller');
    is_deeply($got[4], { type => 'pitch_bend', channel => 3, value => -4096 }, 'the bend');
    is_deeply([ map { [ $_->{number}, $_->{value} ] } @got[ 5, 6 ] ], [ [ 1, 7 ], [ 33, 104 ] ], '14 bits: MSB and LSB');
    is_deeply([ map { [ $_->{number}, $_->{value} ] } @got[ 7 .. 10 ] ], [ [ 101, 0 ], [ 100, 0 ], [ 6, 12 ], [ 38, 0 ] ], 'an RPN as its controllers');
    is_deeply($got[11], { type => 'sysex', data => "\x7f\x7f\x04\x01\x00\x40\xf7" }, 'system exclusive, whole');
}

# Playing what comes in: a note sent is heard within a quantum.
SKIP: {
    skip 'no ALSA sequencer here', 3 unless eval { Peta::Synth::Input->new; 1 };
    require Peta::Synth;
    my @heard;
    my $out = bless { heard => \@heard }, 'Collect';
    sub Collect::write ($self, $l, $r) { push @{ $self->{heard} }, [ @$l ] }
    sub Collect::stop  ($self) { }
    my ($quanta, $address) = (0);
    my $done = Peta::Synth->play_live(in => 'none', rate => 24000, partials => 8, engine => 'perl', quantum => 128, output => $out,
        stop => sub { $quanta >= 40 },
        progress => sub ($synth, $in) {
            $quanta++;
            return unless $quanta == 10;
            my ($c, $p) = split /:/, $in->address;
            open my $seq, '+<:raw', '/dev/snd/seq' or die;
            syswrite $seq, pack('C C c C x8 C C C C a12', 6, 0, 0, 253, 0, 0, $c, $p, pack 'C C C C I', 0, 69, 110, 0, 0);
        });
    is($done->{notes}, 1, 'live: the note came in');
    my ($first) = grep { grep { abs > 1e-4 } @{ $heard[$_] } } 0 .. $#heard;
    ok(defined $first, 'and was heard');
    is($first, 10, 'in the quantum after it came');
}

done_testing;

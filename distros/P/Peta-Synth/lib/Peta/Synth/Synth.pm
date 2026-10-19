package Peta::Synth::Synth;
# ABSTRACT: the synthesizer: channels, voices, engine, reverb

# The synthesizer as it runs: sixteen MIDI channels, the voices that sound,
# an engine that renders them and the reverb, quantum after quantum. Events
# come in two ways: played now (a key pressed in the web page, a message
# from a MIDI device) or scheduled at a sample (a file played). Everything
# is applied at the edge of a control block of 64 samples (1.3 ms at 48 kHz).
#
# A quantum is rendered in three steps:
#
#   1. block by block: the events of the block are applied, and every voice
#      computes its controls (pitch, envelope, gains) for the block
#   2. the engine renders the voices into left, right and a reverb send
#   3. the reverb, the master gain, the equalizer and the limiter
#
# The patches are the synth's own copies of Peta::Synth::Patch's, so that
# one synth can be played with while another renders.

use v5.36;
use Peta::Synth::Patch;
use Peta::Synth::Voice;
use Peta::Synth::Wavetable;
use Peta::Synth::Reverb;
use Peta::Synth::EQ;
use Peta::Synth::Arpeggiator;

our $VERSION = '0.2610180';

use constant BLOCK => 64;

my $DRUM_CHANNEL = 9;

# Drum keys that cut each other off (GM's exclusive classes): the hi-hat's
# closed, pedal and open; the whistles, the guiros, the cuicas, the triangles.
my %EXCLUSIVE = (42 => 1, 44 => 1, 46 => 1, 71 => 2, 72 => 2, 73 => 3, 74 => 3, 78 => 4, 79 => 4, 80 => 5, 81 => 5);

# GS and XG's part numbers (as their system exclusive messages count them)
# to channels: GS counts part 10 first.
my @GS_PART = (9, 0 .. 8, 10 .. 15);

# Fidelity: what may be left out that is hardly heard, for playing on a
# machine that cannot keep up. Voices cost (above all on the GPU, where a
# partial costs next to nothing): a voice that has fallen under quiet of its
# full level (dB) fades out in 5 ms and ends, not at -80 dB; at most voices
# sound at once. High leaves nothing out: what renders sample for sample as
# it always has.
my %FIDELITY = (
    high => {},
    mid  => { quiet => -60 },
    low  => { quiet => -45, voices => 48 },
);

sub new ($class, %arg) {
    my $self = bless {
        rate     => $arg{rate}     // 48000,
        partials => $arg{partials} // 48,      # most partials per voice
        voices   => $arg{voices}   // 256,     # most voices at once
        fidelity => $arg{fidelity} // 'high',  # what may be left out (%FIDELITY)
        gain     => $arg{gain}     // 0.3,     # master
        limiter  => $arg{limiter}  // 1,
        filter   => $arg{filter},              # a sub: which notes to play (for the workers of an offline render)
        now      => 0,                         # the sample the next quantum starts at
        queue    => [],                        # [sample, event], in order
        active   => [],                        # the voices that sound
        count    => 0,                         # notes started, the seed of the next voice
        programs => {},                        # the synth's own patches, as asked for
        drums    => {},
        limit    => 1,                         # the limiter's gain
        stats    => { notes => 0, peak_voices => 0, voice_blocks => 0, partial_blocks => 0 },
    }, $class;
    die "no fidelity '$self->{fidelity}'\n" if !$FIDELITY{ $self->{fidelity} };
    die "no fidelity '$self->{fidelity}'\n" if !$FIDELITY{ $self->{fidelity} };

    $self->{engine} = $arg{engine} // do {
        require Peta::Synth::Engine;
        Peta::Synth::Engine::create('auto', rate => $self->{rate}, partials => $self->{partials});
    };

    # Harmonic partials read from wave sequences (Peta::Synth::Wavetable): a
    # store, kept with the synthesizer, or given (shared, made ahead); 0 for
    # none, every partial turned. By default as the engine fares better (the
    # GPU turning partials, the others reading tables).
    my $engine = $self->{engine};
    my $waves  = $arg{waves} // ($engine->can('reads_waves') ? $engine->reads_waves : 1);
    $self->{waves} = ref $waves ? $waves : $waves ? Peta::Synth::Wavetable->new : undef;

    $self->{reverb} = Peta::Synth::Reverb->new(rate => $self->{rate}, %{ $arg{reverb} // {} });
    $self->{eq}     = Peta::Synth::EQ->new(rate => $self->{rate}, bands => $arg{eq} // {});

    # Each channel's equalizer: gains on its voices' partials. A mixer
    # setting, not MIDI's: a reset leaves it.
    $self->{channel_eq} = [ map { Peta::Synth::EQ->new(rate => $self->{rate}) } 0 .. 15 ];

    # Each channel's arpeggiator, made when it is first asked for; a reset
    # forgets its keys and what a file set, not its own settings.
    $self->{arps}    = [];
    $self->{arp_own} = [];

    $self->reset;
    return $self;
}

sub rate    ($self) { return $self->{rate} }
sub now     ($self) { return $self->{now} }
sub engine  ($self) { return $self->{engine} }
sub waves   ($self) { return $self->{waves} }
sub reverb  ($self) { return $self->{reverb} }
sub eq      ($self) { return $self->{eq} }
sub stats   ($self) { return $self->{stats} }
sub active  ($self) { return scalar @{ $self->{active} } }
sub pending ($self) { return scalar @{ $self->{queue} } }
sub channel ($self, $number) { return $self->{channels}[$number] }

# A channel's equalizer, and changes to it: set_channel_eq($channel, band =>
# { freq, gain, q }, ...), heard at once in the voices that sound.
sub channel_eq ($self, $n) { return $self->{channel_eq}[$n] }

sub set_channel_eq ($self, $n, %bands) {
    my $eq = $self->{channel_eq}[$n] // die "no channel $n\n";
    $eq->set(%bands);
    $_->equalize($eq) for grep { $_->{channel} == $n } @{ $self->{active} };
    return $self;
}

# How hard the machine works to keep up, for playing as it renders: the
# seconds a render took against the seconds of sound it made, smoothed.
sub account ($self, $took, $samples) {
    $self->{load}  = 0.9 * ($self->{load} // 0) + 0.1 * ($took * $self->{rate} / $samples);
    $self->{since} = ($self->{since} // 0) + $samples;
    return $self->{load};
}

sub load ($self) { return $self->{load} // 0 }

# Quality that follows the machine: fewer partials for new notes when the
# rendering takes most of the time there is, more again (up to $most) when
# there is room; at most once a second of sound.
sub adapt ($self, $most) {
    return if ($self->{since} // 0) < $self->{rate};

    my $partials = $self->{partials};
    my $load     = $self->load;
    if ($load > 0.75 && $partials > 4) {
        $self->{partials} = int($partials * 0.75) || 4;
    }
    elsif ($load < 0.35 && $partials < $most) {
        my $more = int($partials * 1.25) + 1;
        $self->{partials} = $more > $most ? $most : $more;
    }
    else {
        return;
    }
    $self->{since} = 0;
    return $self->{partials};
}

sub set ($self, $name, $value) {
    die "cannot set '$name'\n" if $name !~ /\A(?:partials|voices|gain|limiter|fidelity)\z/;
    die "no fidelity '$value'\n" if $name eq 'fidelity' && !$FIDELITY{$value};
    $self->{$name} = $value;
    return $self;
}

# A channel as MIDI starts it.
sub _channel ($number, $mute = 0) {
    return {
        number      => $number,
        program     => 0,
        bank        => 0,        # CC0, as the last bank select said
        variation   => 0,        # the GS bank of the program's variation, as the last program change picked it
        kit         => 0,        # the drum kit, the same way
        drum        => $number == $DRUM_CHANNEL ? 1 : 0,
        volume      => 100,      # CC7
        expression  => 127,      # CC11
        pan         => 64,       # CC10
        send        => 40,       # CC91, the reverb
        chorus      => 0,        # CC93
        mod         => 0,        # CC1, 0 .. 1
        breath      => 0,        # CC2, 0 .. 1
        foot        => 0,        # CC4, 0 .. 1
        pressure    => 0,        # channel pressure, 0 .. 1
        bend        => 0,        # -1 .. 1
        range       => 2,        # the bend's, semitones (RPN 0)
        tune        => 0,        # semitones (RPN 1 and 2)
        mod_range   => 50,       # cents of vibrato at full modulation (RPN 5)
        sound       => { map { $_ => 64 } 70 .. 79 },    # CC70 .. 79, the sound controllers (64: as the patch)
        sustain     => 0,        # the pedals: CC64,
        sostenuto   => {},       # CC66 (the keys it holds),
        soft        => 0,        # CC67,
        legato      => 0,        # CC68
        portamento  => 0,        # CC65
        porta_time  => 0,        # CC5
        porta_from  => undef,    # CC84
        mono        => 0,        # mono mode (CC126); legato then too
        param       => undef,    # the RPN or NRPN data entry sets: [ 'r' or 'n', msb, lsb ]
        data        => {},       # the values set, by "r msb lsb" or "n msb lsb"
        drum_keys   => {},       # per drum key: pitch, level, pan, reverb, chorus (GS and XG's NRPNs)
        cc          => { 7 => 100, 10 => 64, 11 => 127, 91 => 40, map { $_ => 64 } 70 .. 79 },    # every controller's last value
        dest        => {},       # GM2's controller destinations, by source (see _destination)
        held        => {},       # the voices held by key,
        pedal       => [],       # and by the pedals
        stack       => [],       # in mono, the keys held, in order
        last_key    => undef,
        mute        => $mute,    # the page's, not MIDI's
    };
}

# All channels to their defaults and every voice gone; the patches stay.
sub reset ($self) {
    $self->{channels} = [ map { _channel($_) } 0 .. 15 ];
    $self->{master}   = { volume => 1, balance => 0, fine => 0, coarse => 0 };
    $self->{active}   = [];
    $self->{queue}    = [];
    delete $self->{state};
    $self->{reverb}->clear;
    $self->{eq}->clear;
    $self->_arps_stop;
    $self->forget_held;
    delete $self->{held_back};
    return $self;
}

# A channel's arpeggiator (Peta::Synth::Arpeggiator): while it is on, the
# channel's keys go to it and it plays them. set_arpeggiator($n, %fields)
# changes its settings; turned off, what it plays is let go.
sub arpeggiator ($self, $n) {
    die "no channel $n\n" if $n < 0 || $n > 15;
    return $self->{arps}[$n] //= Peta::Synth::Arpeggiator->new(rate => $self->{rate}, channel => $n,
        settings => { defined $self->{tempo} ? (tempo => $self->{tempo}) : () });
}

# set_arpeggiator: the channel's own settings (the page's, played live, a
# bank's), which a reset and a new file come back to; what a file sets
# (_arp_set) lasts until then.
sub set_arpeggiator ($self, $n, %fields) {
    $self->{arp_own}[$n] = { %{ $self->{arp_own}[$n] // {} }, %fields };
    return $self->_arp_change($n, %fields);
}

sub _arp_change ($self, $n, %fields) {
    my $arp = $self->arpeggiator($n);
    my $was = $arp->on;
    $arp->set(%fields);
    $self->_enqueue($arp->stop($self->{now})) if $was && !$arp->on;
    return $self;
}

# A file's tempo: the arpeggiators', until something else sets theirs.
sub _tempo ($self, $usec, $at) {
    return if !$usec;
    my $bpm = 60_000_000 / $usec;
    $bpm = $bpm < 30 ? 30 : $bpm > 300 ? 300 : $bpm;
    $self->{tempo} = $bpm;
    for my $n (grep { defined $self->{arps}[$_] } 0 .. 15) {
        $self->_arp_set($n, tempo => $bpm, $at);
    }
    return;
}

# Settings made by hand (on the page, or by MIDI played live) are held
# against the other MIDI (a file's): what a channel plays ('program': its
# bank select and program change), its mixer's controllers ('cc 7'), its
# arpeggiator's settings ('arp mode'). While one is held, the file's events
# for it are kept aside, the last of each; let go, they apply, and the
# channel is as the file has it by then. A reset keeps what is held, and the
# file's value is the reset's.
my %HELD_CC = map { $_ => 1 } 5, 7, 10, 91, 93, 70 .. 79;    # settings; not what is played (wheels, pedals, expression)

# An event's setting, if it can be held: (what, its part).
sub _setting ($event) {
    my $type = $event->{type};
    return ("arp $event->{name}", '') if $type eq 'arp';
    return ('program', 'program')     if $type eq 'program';
    return                            if $type ne 'controller';
    my $number = $event->{number};
    return ('program', "cc $number") if $number == 0 || $number == 32;
    return ("cc $number", '')        if $HELD_CC{$number};
    return;
}

# An event played by hand: applied at once, what it sets held.
sub by_hand ($self, $event) {
    local $self->{by_hand} = 1;
    return $self->play($event);
}

# What a channel holds, by name ('program', 'cc 7', 'arp mode').
sub held ($self, $n) { return [ sort keys %{ $self->{hand}[$n] } ] }

# A setting let go (or every one of the channel's): as the file has it now.
sub let_go ($self, $n, $what = undef) {
    for my $name (defined $what ? $what : @{ $self->held($n) }) {
        delete $self->{hand}[$n]{$name} or next;
        my $aside = delete $self->{aside}[$n]{$name};
        $self->_apply($aside->{$_}, $self->{now}) for sort keys %$aside;
    }
    return $self;
}

# Nothing held any more, as it is now: a new file.
sub forget_held ($self) {
    $self->{hand}  = [ map { {} } 0 .. 15 ];
    $self->{aside} = [ map { {} } 0 .. 15 ];
    return $self;
}

# A setting as the channel has it now, as the events that would set it.
sub _as_now ($self, $n, $what) {
    my $c = $self->{channels}[$n];
    if ($what eq 'program') {
        return {
            'cc 0'  => { type => 'controller', channel => $n, number => 0,  value => $c->{bank} },
            'cc 32' => { type => 'controller', channel => $n, number => 32, value => $c->{cc}{32} // 0 },
            program => { type => 'program', channel => $n, program => $c->{program} },
        };
    }
    if ($what =~ /\Acc (\d+)\z/) {
        return { '' => { type => 'controller', channel => $n, number => $1, value => $c->{cc}{$1} // 0 } };
    }
    my ($name) = $what =~ /\Aarp (\w+)\z/;
    return { '' => { type => 'arp', channel => $n, name => $name, value => $self->arpeggiator($n)->params->{$name} } };
}

# An arpeggiator's setting as MIDI sets it: an event, so that it can be held (see by_hand).
sub _arp_set ($self, $n, $name, $value, $at) {
    $self->_apply({ type => 'arp', channel => $n, name => $name, value => $value }, $at);
    return;
}

# Every arpeggiator's keys forgotten (what they play is let go with the voices).
sub _arps_stop ($self) {
    $_->stop($self->{now}) for grep { defined } @{ $self->{arps} // [] };
    return;
}

# What the arpeggiators that are on play in [$from, $to), queued.
sub _arpeggiate ($self, $from, $to) {
    $self->_enqueue($_->events($from, $to)) for grep { defined && $_->on } @{ $self->{arps} };
    return;
}

# Events ([sample, event]) into the queue at their places, after what is
# already there at the same sample.
sub _enqueue ($self, @entries) {
    my $queue = $self->{queue};
    for my $entry (@entries) {
        my ($low, $high) = (0, scalar @$queue);
        while ($low < $high) {
            my $mid = ($low + $high) >> 1;
            if ($queue->[$mid][0] <= $entry->[0]) { $low = $mid + 1 } else { $high = $mid }
        }
        splice @$queue, $low, 0, $entry;
    }
    return;
}

# Every channel and the master as MIDI starts them, what sounds let go: a
# reset by MIDI (GM, GS, XG), or a file played from a point in it. The
# mutes are the page's, not MIDI's.
sub reset_channels ($self, $at = $self->{now}) {
    for my $c (@{ $self->{channels} }) {
        $_->release($at) for $self->_voices($c);
        $c = _channel($c->{number}, $c->{mute});
    }
    $self->{master} = { volume => 1, balance => 0, fine => 0, coarse => 0 };
    delete $self->{state};
    $self->_arps_stop;

    # The arpeggiators as their own settings have them, not as a file set them.
    delete $self->{tempo};
    for my $n (grep { defined $self->{arps}[$_] } 0 .. 15) {
        $self->_arp_change($n, %{ Peta::Synth::Arpeggiator::defaults() }, %{ $self->{arp_own}[$n] // {} });
    }

    # A reset by hand lets go of what is held. The file's keeps it (the
    # arpeggiators' are their own settings again, which those held are);
    # the file's value is the reset's.
    return $self->forget_held if $self->{by_hand};
    for my $n (0 .. 15) {
        my $hand = $self->{hand}[$n];
        for my $what (grep { !/\Aarp / } sort keys %$hand) {
            $self->{aside}[$n]{$what} = $self->_as_now($n, $what);
            local $self->{by_hand} = 1;
            $self->_apply($hand->{$what}{$_}, $at) for sort keys %{ $hand->{$what} };
        }
    }
    return $self;
}

# The synth's patch for a program (or its variation, by GS bank) or a drum
# key (in a kit), made from the defaults the first time it is asked for.
# Changing its fields changes how the next notes of it sound (and the
# voices that sound, where a field is read live: envelope, pitch, noise
# level). A key a kit does not have as its own is the standard kit's.
# They are kept by number, or 'bank:number' for a variation or a kit's own.
sub program_patch ($self, $number, $bank = 0) {
    return $self->{programs}{ _patch_key($number, $bank) } //= { %{ Peta::Synth::Patch::program($number, $bank) } };
}

sub drum_patch ($self, $key, $kit = 0) {
    $kit = Peta::Synth::Patch::kit_key($kit, $key);
    return $self->{drums}{ _patch_key($key, $kit) } //= { %{ Peta::Synth::Patch::drum($key, $kit) } };
}

sub restore_patch ($self, $kind, $number, $bank = 0) {
    my $drum = $kind eq 'drum';
    $bank = Peta::Synth::Patch::kit_key($bank, $number) if $drum;
    delete $self->{ $drum ? 'drums' : 'programs' }{ _patch_key($number, $bank) };
    return $drum ? $self->drum_patch($number, $bank) : $self->program_patch($number, $bank);
}

sub _patch_key ($number, $bank) { return $bank ? "$bank:$number" : $number }

# A patch's key: (number, bank).
sub _patch_id ($key) {
    my ($number, $bank) = reverse split /:/, $key;
    return ($number, $bank // 0);
}

# What has been changed from the defaults, as a bank: { programs => { n or
# 'bank:n' => { field => value } }, drums => { key or 'kit:key' => { ... } },
# master => { reverb, eq, channels => { n => eq }, arps => { n => settings } } }.
sub edits ($self) {
    require JSON::PP;
    my $json = JSON::PP->new->canonical;
    my %bank;

    for my $kind ([ programs => \&Peta::Synth::Patch::program ], [ drums => \&Peta::Synth::Patch::drum ]) {
        my ($name, $default) = @$kind;
        for my $number (keys %{ $self->{$name} }) {
            my $patch = $self->{$name}{$number};
            my $base  = $default->(_patch_id($number));
            for my $field (keys %$patch) {
                # Lists (formants, partials) compared as what they hold; none is null.
                my ($now, $was) = map { ref ? $json->encode($_) : $_ // '' } $patch->{$field}, $base->{$field};
                $bank{$name}{$number}{$field} = $patch->{$field} if $now ne $was;
            }
        }
    }

    # The master: the reverb's and the equalizers' settings, where they are
    # not the defaults.
    my $rate  = $self->{rate};
    my %fresh = (reverb => Peta::Synth::Reverb->new(rate => $rate)->params, eq => Peta::Synth::EQ->new(rate => $rate)->params);
    my %now   = (reverb => $self->{reverb}->params, eq => $self->{eq}->params);
    for my $part (qw(reverb eq)) {
        $bank{master}{$part} = $now{$part} if $json->encode($now{$part}) ne $json->encode($fresh{$part});
    }
    for my $n (0 .. 15) {
        my $eq = $self->{channel_eq}[$n];
        $bank{master}{channels}{$n} = $eq->params if $eq->active;
    }
    my $plain = Peta::Synth::Arpeggiator::defaults();
    for my $n (0 .. 15) {
        my $mine = $self->{arp_own}[$n] or next;    # not what a file set
        my $own  = { %$plain, %$mine };
        $bank{master}{arps}{$n} = $own if $json->encode($own) ne $json->encode($plain);
    }
    return \%bank;
}

# A bank's changes applied to this synth's patches and master. Unknown
# fields die.
sub apply_edits ($self, $bank) {
    my %known = map { $_ => 1 } Peta::Synth::Patch::fields();
    for my $kind ([ programs => 'program_patch' ], [ drums => 'drum_patch' ]) {
        my ($name, $method) = @$kind;
        for my $number (keys %{ $bank->{$name} // {} }) {
            my $patch   = $self->$method(_patch_id($number));
            my $changes = $bank->{$name}{$number};
            for my $field (keys %$changes) {
                die "a patch has no field '$field'\n" if !$known{$field};
                $patch->{$field} = $changes->{$field};
            }
        }
    }

    my $master = $bank->{master} // {};
    $self->{reverb}->set($_ => $master->{reverb}{$_}) for keys %{ $master->{reverb} // {} };
    $self->{eq}->set(%{ $master->{eq} // {} });
    $self->set_channel_eq($_, %{ $master->{channels}{$_} }) for keys %{ $master->{channels} // {} };
    $self->set_arpeggiator($_, %{ $master->{arps}{$_} }) for keys %{ $master->{arps} // {} };
    return $self;
}

# The events of a key: left out where a file is played from a point in it.
my %NOTE = map { $_ => 1 } qw(note_on note_off key_pressure);

# Events scheduled at times (seconds) from now, as Peta::Synth::MIDI's
# timeline gives them: the channels' and system exclusive messages, and the
# tempo (the arpeggiators'). From
# $from seconds into them, what comes before that sets the channels up at
# once, in its order (programs, controllers, bends, system exclusive), and
# its notes are left out.
sub schedule ($self, $events, $offset = 0, $from = 0) {
    my $rate = $self->{rate};
    my $base = $self->{now} + $offset * $rate;

    # In time order, whatever order they come in (sort is stable: same-sample order kept).
    my @wanted = grep { defined $_->{channel} || $_->{type} eq 'sysex' || $_->{type} eq 'tempo' } @$events;
    @wanted = grep { $_->{time} >= $from || !$NOTE{ $_->{type} } } @wanted if $from;
    my @new = sort { $a->[0] <=> $b->[0] } map { [ int($base + ($_->{time} > $from ? $_->{time} - $from : 0) * $rate + 0.5), $_ ] } @wanted;

    my $queue = $self->{queue};
    if (!@$queue || $new[0] && $new[0][0] >= $queue->[-1][0]) {
        push @$queue, @new;
    }
    else {
        @$queue = sort { $a->[0] <=> $b->[0] } @$queue, @new;
    }
    return scalar @new;
}

# Whether there is anything still to render: events to come, voices that
# sound, or a reverb tail that has not died away.
sub busy ($self) {
    return @{ $self->{queue} } || @{ $self->{active} } || !$self->{reverb}->quiet;
}

# Scheduled events dropped and every voice released: a file stopped.
sub stop ($self) {
    $self->{queue} = [];
    $self->_arps_stop;
    for my $c (@{ $self->{channels} }) {
        @$c{qw(held pedal sustain stack)} = ({}, [], 0, []);
    }
    $_->release($self->{now}) for @{ $self->{active} };
    return $self;
}

sub panic ($self) {
    $self->stop;
    $_->kill($self->{now}) for @{ $self->{active} };
    return $self;
}

# An event now: it takes effect at the start of the next quantum.
sub play ($self, $event) {
    $self->_apply($event, $self->{now});
    return $self;
}

sub _apply ($self, $event, $at) {
    my $type = $event->{type};
    delete $self->{state};    # the channels' gains, bend and modulation, to be worked out again

    return $self->_sysex($event->{data}, $at)  if $type eq 'sysex';
    return $self->_tempo($event->{usec}, $at) if $type eq 'tempo';

    my $c = $self->{channels}[ $event->{channel} // return ];
    my $n = $c->{number};
    if (my ($what, $part) = _setting($event)) {
        # Held by hand, or kept aside while it is (see by_hand).
        my $held = $self->{hand}[$n]{$what};
        if ($self->{by_hand}) {
            $self->{aside}[$n]{$what} //= $self->_as_now($n, $what);
            $held = $self->{hand}[$n]{$what} //= {};
            $held->{$part} = $event;
            if ($part eq 'program') {
                # A program change alone: with the bank it was chosen from.
                my $now = $self->_as_now($n, 'program');
                $held->{$_} //= $now->{$_} for 'cc 0', 'cc 32';
            }
        }
        elsif ($held) {
            $self->{aside}[$n]{$what}{$part} = $event;
            return;
        }
    }
    if ($type eq 'arp') {
        return $self->set_arpeggiator($n, $event->{name} => $event->{value}) if $self->{by_hand};
        return $self->_arp_change($n, $event->{name} => $event->{value});
    }

    my $arp = $self->{arps}[$n];
    if ($type eq 'arp_step') {
        # An arpeggiator's step: its notes of the keys held now, and what is due next.
        return if !$arp;
        $self->_apply($_->[1], $at) for $arp->step($at);
        $self->_enqueue($arp->events($at, $self->{until} // $at));
        return;
    }
    if ($arp && $arp->on && !$event->{arp} && !$c->{drum} && ($type eq 'note_on' || $type eq 'note_off')) {
        # The key to the arpeggiator; its first notes at once.
        if ($type eq 'note_on' && $event->{velocity}) { $arp->press($event->{key}, $event->{velocity}, $at) }
        else                                          { $arp->release($event->{key}, $at) }
        $self->_enqueue($arp->events($at, $self->{until} // $at));
        return;
    }
    if ($type eq 'note_on') {
        if   ($event->{velocity}) { $self->_note_on($c, $event->{key}, $event->{velocity}, $at) }
        else                      { $self->_note_off($c, $event->{key}, $at) }
    }
    elsif ($type eq 'note_off') {
        $self->_note_off($c, $event->{key}, $at, $event->{velocity});
    }
    elsif ($type eq 'program') {
        # The bank selected before it picks the variation, and on a drum channel the program the kit.
        $c->{program}   = $event->{program};
        $c->{variation} = Peta::Synth::Patch::variation($c->{bank}, $c->{cc}{32} // 0, $c->{program});
        $c->{kit}       = Peta::Synth::Patch::kit($c->{program});
    }
    elsif ($type eq 'pitch_bend') {
        $c->{bend} = $event->{value} / 8192;
    }
    elsif ($type eq 'controller') {
        $self->_controller($c, $event->{number}, $event->{value}, $at);
    }
    elsif ($type eq 'channel_pressure') {
        $c->{pressure} = $event->{value} / 127;
    }
    elsif ($type eq 'key_pressure') {
        my $p = $event->{value} / 127;
        $_->{pressure} = $p for grep { $_->{key} == $event->{key} } $self->_voices($c);
    }
    return;
}

# The voices of a channel that have not been let go (held, or held by a pedal).
sub _voices ($self, $c) {
    my $n = $c->{number};
    return grep { $_->{channel} == $n && !defined $_->{released} && !defined $_->{killed} } @{ $self->{active} };
}

sub _note_on ($self, $c, $key, $velocity, $at) {
    return $self->_mono_on($c, $key, $velocity, $at) if ($c->{mono} || $c->{legato}) && !$c->{drum};

    if ($c->{drum}) {
        # A drum of an exclusive class cuts off the others of its class.
        if (my $class = $EXCLUSIVE{$key}) {
            my @mine = grep { $_->{channel} == $c->{number} } @{ $self->{active} };
            $_->kill($at) for grep { ($EXCLUSIVE{ $_->{key} } // 0) == $class && !defined $_->{killed} } @mine;
        }
    }
    else {
        # The same key again: the voice it sounds in is let go.
        if ($c->{held}{$key}) {
            $_->release($at) for @{ delete $c->{held}{$key} };
        }
        my @pedal;
        for my $voice (@{ $c->{pedal} }) {
            if ($voice->{key} == $key) { $voice->release($at) } else { push @pedal, $voice }
        }
        $c->{pedal} = \@pedal;
    }

    # Portamento (not on drums): from CC84's key, once; else from the last key
    # while CC65 is down.
    my $from = delete $c->{porta_from};
    $from //= $c->{last_key} if $c->{portamento};
    $from = undef if $c->{drum};
    $c->{last_key} = $key if !$c->{drum};

    my @glide = defined $from ? (glide => [ $from - $key, _porta_time($c) ]) : ();
    my $voice = $self->_voice($c, $key, $velocity, $at, @glide) or return;
    push @{ $c->{held}{$key} }, $voice;
    return $voice;
}

# Mono (CC126, or the legato pedal): one voice a channel. A key pressed
# while another is held takes over legato (no attack; gliding from the key
# that sounded where portamento is on); let go, the key held before it
# sounds again. The voice that takes over is a new one: its spectrum is
# its key's, and the old one fades in 5 ms.
sub _mono_on ($self, $c, $key, $velocity, $at) {
    my $stack    = $c->{stack};
    my $sounding = @$stack ? $stack->[-1][0] : undef;
    @$stack = grep { $_->[0] != $key } @$stack;
    push @$stack, [ $key, $velocity ];

    my $from = delete $c->{porta_from};
    $from //= $c->{last_key} if $c->{portamento};
    $c->{last_key} = $key;
    return $self->_mono_sound($c, $key, $velocity, $at, defined $sounding, $from);
}

sub _mono_sound ($self, $c, $key, $velocity, $at, $legato, $from) {
    $_->kill($at) for $self->_voices($c);
    $c->{pedal} = [];
    $c->{held}  = {};

    my $time  = defined $from ? _porta_time($c) : 0;
    my @glide = defined $from && $from != $key ? (glide => [ $from - $key, $time ]) : ();
    my $voice = $self->_voice($c, $key, $velocity, $at, legato => $legato, @glide) or return;
    $c->{held}{$key} = [$voice];
    return $voice;
}

sub _mono_off ($self, $c, $key, $at, $velocity) {
    my $stack = $c->{stack};
    my $was   = @$stack ? $stack->[-1][0] : undef;
    @$stack = grep { $_->[0] != $key } @$stack;
    return if !defined $was || $was != $key;

    if (@$stack) {
        my ($back, $back_velocity) = @{ $stack->[-1] };
        $c->{last_key} = $back;
        return $self->_mono_sound($c, $back, $back_velocity, $at, 1, $c->{portamento} ? $key : undef);
    }
    for my $voice (@{ delete $c->{held}{$key} // [] }) {
        $self->_let_go($c, $voice, $at, $velocity);
    }
    return;
}

sub _note_off ($self, $c, $key, $at, $velocity = undef) {
    return $self->_mono_off($c, $key, $at, $velocity) if ($c->{mono} || $c->{legato}) && !$c->{drum};

    my $held  = $c->{held}{$key} or return;
    my $voice = shift @$held;
    delete $c->{held}{$key} if !@$held;
    $self->_let_go($c, $voice, $at, $velocity);
    return;
}

# A key let go: its voice released, or held by a pedal (its note-off
# velocity kept for when the pedal lets go).
sub _let_go ($self, $c, $voice, $at, $velocity) {
    if ($c->{sustain} || $c->{sostenuto}{ $voice->{key} }) {
        push @{ $c->{pedal} }, $voice;
        $voice->off_velocity($velocity);
    }
    else {
        $voice->release($at, $velocity);
    }
    return;
}

# The seconds a portamento takes (CC5: 0 none, 64 about 0.15 s, 127 about 10 s).
sub _porta_time ($c) {
    my $v = $c->{porta_time};
    return $v ? 0.002 * exp($v * 0.0675) : 0;
}

# A new voice of a note on channel $c, as the channel shapes it (the sound
# controllers, the soft pedal, a drum key's own settings); undef where this
# synth does not play it (a worker's share, a muted channel).
sub _voice ($self, $c, $key, $velocity, $at, %more) {
    my $id = $self->{count}++;
    return if $self->{filter} && !$self->{filter}->($id);
    return if $c->{mute};

    my $patch = $c->{drum} ? $self->drum_patch($key, $c->{kit}) : $self->program_patch($c->{program}, $c->{variation});

    # The sound controllers, 64 as the patch is: times halve or double every
    # 16 steps; brightness moves the cutoff by up to four octaves; resonance
    # raises the cutoff's peak (at most about 16 dB). A patch with a filter
    # has brightness and resonance move it instead, as the note sounds.
    my $sound = $c->{sound};
    my %shape = (
        release => 2**(($sound->{72} - 64) / 16),
        attack  => 2**(($sound->{73} - 64) / 16),
        decay   => 2**(($sound->{75} - 64) / 16),
        bright  => 2**(($sound->{74} - 64) / 16),
        q       => 2**(($sound->{71} - 64) / 24),
    );
    @shape{qw(bright q)} = (1, 1) if $patch->{filter} ne 'off';
    if ($c->{soft}) {
        $shape{level} = 0.7;
        $shape{bright} *= 0.7;
    }

    # A drum key's own pitch, level, pan and sends (GS and XG).
    my ($tune, $pan, $send, $chorus) = (0, 0, 1, $c->{chorus} / 127);
    if ($c->{drum} && (my $d = $c->{drum_keys}{$key})) {
        $tune = ($d->{pitch} // 0) + ($d->{fine} // 0) / 100;
        $shape{level} = ($shape{level} // 1) * ($d->{level} // 127)**2 / 16129;
        $pan  = (($d->{pan} // 64) - 64) / 64;
        $send = ($d->{reverb} // 127) / 127;
        $chorus *= ($d->{chorus} // 127) / 127;
    }

    # A controller destination that moves the cutoff gives the note a filter.
    my $cutoff = grep { $_->[1] != 64 || $_->[4] } values %{ $c->{dest} };

    my $voice = Peta::Synth::Voice->new($patch,
        key            => $key,
        velocity       => $velocity,
        channel        => $c->{number},
        rate           => $self->{rate},
        partials       => $self->{partials},
        start          => $at,
        seed           => $id + 1,
        id             => $id,
        chorus         => $chorus,
        shape          => \%shape,
        tune           => $tune,
        pan            => $pan,
        send           => $send,
        cutoff_control => $cutoff,
        waves          => $self->{waves},
        %more,
    );
    my $eq = $self->{channel_eq}[ $c->{number} ];
    $voice->equalize($eq) if $eq->active;

    push @{ $self->{active} }, $voice;
    $self->{stats}{notes}++;
    $self->_steal($at) if @{ $self->{active} } > $self->_most_voices;
    return $voice;
}

# The most voices at once: the set number, or the fidelity's if fewer.
sub _most_voices ($self) {
    my $most = $FIDELITY{ $self->{fidelity} }{voices} // return $self->{voices};
    return $most < $self->{voices} ? $most : $self->{voices};
}

# Too many voices: those already let go end first, oldest first, then the oldest of the rest.
sub _steal ($self, $at) {
    my @live = grep { !defined $_->{killed} } @{ $self->{active} };
    my $over = @live - $self->_most_voices;
    return if $over <= 0;

    my @order = map { $_->[1] }
        sort { $b->[0] <=> $a->[0] || $a->[1]{start} <=> $b->[1]{start} }
        map { [ defined $_->{released} ? 1 : 0, $_ ] } @live;
    $_->kill($at) for @order[ 0 .. $over - 1 ];
    return;
}

# The controllers that only set a channel's field: the field, and what the
# value is divided by.
my %SIMPLE_CONTROLLER = (
    1  => [ mod        => 127 ],
    2  => [ breath     => 127 ],
    4  => [ foot       => 127 ],
    5  => [ porta_time => 1 ],
    7  => [ volume     => 1 ],
    10 => [ pan        => 1 ],
    11 => [ expression => 1 ],
    84 => [ porta_from => 1 ],
    91 => [ send       => 1 ],
    93 => [ chorus     => 1 ],
);

sub _controller ($self, $c, $number, $value, $at) {
    $c->{cc}{$number} = $value if $number < 120;
    my $on = $value >= 64 ? 1 : 0;

    if (my $simple = $SIMPLE_CONTROLLER{$number}) {
        my ($field, $scale) = @$simple;
        $c->{$field} = $value / $scale;
    }
    elsif ($number == 0) {
        # Bank 120 and 127 are drums (GM2, XG), 121 melodic (GM2); GS and XG
        # banks of variations play their GM program.
        $c->{bank} = $value;
        $c->{drum} = 1 if $value == 120 || $value == 127;
        $c->{drum} = 0 if $value == 121;
    }
    elsif ($number >= 70 && $number <= 79)        { $c->{sound}{$number} = $value }
    elsif ($number == 65)                         { $c->{portamento} = $on }
    elsif ($number == 67)                         { $c->{soft} = $on }
    elsif ($number == 68)                         { $self->_mode($c, legato => $on, $at) }
    elsif ($number == 64)                         { $self->_sustain($c, $on, $at) }
    elsif ($number == 66)                         { $self->_sostenuto($c, $on, $at) }
    elsif ($number == 101 || $number == 100)      { _select_param($c, 'r', $number == 101 ? 1 : 2, $value) }
    elsif ($number == 99 || $number == 98)        { _select_param($c, 'n', $number == 99 ? 1 : 2, $value) }
    elsif ($number == 6 || $number == 38 || $number == 96 || $number == 97) { $self->_data_entry($c, $number, $value, $at) }
    elsif ($number == 80)                         { $self->_arp_set($c->{number}, on => $on, $at) }       # general purpose 5
    elsif ($number == 81)                         { $self->_arp_set($c->{number}, latch => $on, $at) }    # general purpose 6
    elsif ($number == 120)                        { $self->_sound_off($c, $at) }
    elsif ($number == 123)                        { $self->_notes_off($c, $at) }
    elsif ($number == 121)                        { $self->_reset_controllers($c, $at) }
    elsif ($number == 124 || $number == 125)      { $self->_notes_off($c, $at) }    # omni off, on
    elsif ($number == 126)                        { $self->_mode($c, mono => 1, $at) }
    elsif ($number == 127)                        { $self->_mode($c, mono => 0, $at) }
    return;
}

# The sustain pedal: let up, the voices it held are let go (but those the
# sostenuto pedal holds).
sub _sustain ($self, $c, $down, $at) {
    if ($c->{sustain} && !$down) {
        my @still;
        for my $voice (@{ $c->{pedal} }) {
            if ($c->{sostenuto}{ $voice->{key} }) { push @still, $voice } else { $voice->release($at) }
        }
        $c->{pedal} = \@still;
    }
    $c->{sustain} = $down;
    return;
}

# The sostenuto pedal: pressed, it holds the keys held now; let up, the
# voices it held are let go (but those the sustain pedal holds).
sub _sostenuto ($self, $c, $down, $at) {
    if ($down) {
        $c->{sostenuto} = { map { $_ => 1 } keys %{ $c->{held} } };
        return;
    }
    $c->{sostenuto} = {};
    my @still;
    for my $voice (@{ $c->{pedal} }) {
        if ($c->{sustain}) { push @still, $voice } else { $voice->release($at) }
    }
    $c->{pedal} = \@still;
    return;
}

# All sound off: every voice of the channel ends within milliseconds.
sub _sound_off ($self, $c, $at) {
    $_->kill($at) for grep { $_->{channel} == $c->{number} } @{ $self->{active} };
    @$c{qw(held pedal)} = ({}, []);
    return;
}

# All notes off: every key and pedal let go.
sub _notes_off ($self, $c, $at) {
    for my $voices (values %{ $c->{held} }) { $_->release($at) for @$voices }
    $_->release($at) for @{ $c->{pedal} };
    @$c{qw(held pedal)} = ({}, []);
    return;
}

# Reset all controllers, as GM2 says: not volume, pan, the sends, the sound controllers.
sub _reset_controllers ($self, $c, $at) {
    @$c{qw(expression mod breath foot pressure bend sustain soft portamento param)} = (127, 0, 0, 0, 0, 0, 0, 0, 0, undef);
    @{ $c->{cc} }{ 1, 2, 4, 11, 64 .. 67 } = (0, 0, 0, 127, 0, 0, 0, 0);
    $c->{sostenuto} = {};
    $_->{pressure} = 0 for grep { $_->{channel} == $c->{number} } @{ $self->{active} };
    $_->release($at) for @{ $c->{pedal} };
    $c->{pedal} = [];
    return;
}

# Mono or poly mode, the legato pedal: the notes are let go first.
sub _mode ($self, $c, $name, $on, $at) {
    return if $c->{$name} == $on;
    $self->_notes_off($c, $at);
    $c->{$name}  = $on;
    $c->{stack}  = [];
    return;
}

# An RPN ('r') or NRPN ('n') chosen for data entry, one byte at a time
# ($which: 1 the MSB, 2 the LSB); 127, 127 is none.
sub _select_param ($c, $kind, $which, $value) {
    my @p = $c->{param} && $c->{param}[0] eq $kind ? @{ $c->{param} } : ($kind, 127, 127);
    $p[$which] = $value;
    $c->{param} = $p[1] == 127 && $p[2] == 127 ? undef : \@p;
    return;
}

# The RPNs and NRPNs, as their values are, from data entry: CC6 (the MSB,
# which clears the LSB), CC38 (the LSB), CC96 and 97 (one step up or down:
# the LSB where it counts cents, else the MSB).
my %PARAM_DEFAULT = ('r 0 0' => [ 2, 0 ], 'r 0 1' => [ 64, 0 ], 'r 0 2' => [ 64, 0 ], 'r 0 5' => [ 0, 64 ]);
my %FINE          = map { $_ => 1 } 'r 0 0', 'r 0 1', 'r 0 5';

# GS and XG's NRPNs: the part's vibrato, filter and envelope (1, lsb), as
# the sound controllers; a drum key's pitch, level, pan and sends (msb, key).
my %NRPN_SOUND = (0x08 => 76, 0x09 => 77, 0x0a => 78, 0x20 => 74, 0x21 => 71, 0x63 => 73, 0x64 => 75, 0x66 => 72);
my %NRPN_KEY   = (0x18 => 'pitch', 0x19 => 'fine', 0x1a => 'level', 0x1c => 'pan', 0x1d => 'reverb', 0x1e => 'chorus');

sub _data_entry ($self, $c, $number, $value, $at) {
    my $p    = $c->{param} or return;
    my $name = join ' ', @$p;
    my $data = $c->{data}{$name} //= [ @{ $PARAM_DEFAULT{$name} // [ 64, 0 ] } ];

    if ($number == 6) {
        @$data = ($value, 0);
    }
    elsif ($number == 38) {
        $data->[1] = $value;
    }
    else {
        my $v = $FINE{$name} ? $data->[0] * 128 + $data->[1] : $data->[0] * 128;
        $v += ($number == 96 ? 1 : -1) * ($FINE{$name} ? 1 : 128);
        $v = 0     if $v < 0;
        $v = 16383 if $v > 16383;
        @$data = (int($v / 128), $v % 128);
    }

    my ($msb, $lsb) = @$data;
    my ($kind, $hi, $lo) = @$p;
    if ($kind eq 'r') {
        if    ($hi == 0 && $lo == 0) { $c->{range}     = $msb + $lsb / 100 }
        elsif ($hi == 0 && $lo == 1) { $c->{fine}      = ($msb * 128 + $lsb - 8192) / 8192 }
        elsif ($hi == 0 && $lo == 2) { $c->{coarse}    = $msb - 64 }
        elsif ($hi == 0 && $lo == 5) { $c->{mod_range} = $msb * 100 + $lsb * 100 / 128 }
        $c->{tune} = ($c->{coarse} // 0) + ($c->{fine} // 0);
        return;
    }

    if ($hi == Peta::Synth::Arpeggiator::NRPN) {
        my ($name, $setting) = Peta::Synth::Arpeggiator::nrpn($lo, $msb, $lsb) or return;
        $self->_arp_set($c->{number}, $name => $setting, $at);
    }
    elsif ($hi == 1 && $NRPN_SOUND{$lo}) {
        $c->{sound}{ $NRPN_SOUND{$lo} } = $msb;
    }
    elsif (my $what = $NRPN_KEY{$hi}) {
        $c->{drum_keys}{$lo}{$what} = $what eq 'pitch' || $what eq 'fine' ? $msb - 64 : $msb;
    }
    return;
}

# System exclusive: the resets (GM, GM2, GS, XG), the master's volume,
# balance and tuning (universal, GS, XG), GM2's controller destinations, and
# a part made a drum part (GS, XG). $data is what follows F0.
sub _sysex ($self, $data, $at) {
    my @b = unpack 'C*', $data // '';
    pop @b if @b && $b[-1] == 0xf7;
    return if @b < 4;

    return $self->_universal($at, @b) if $b[0] == 0x7e || $b[0] == 0x7f;
    return $self->_roland($at, @b)    if $b[0] == 0x41 && @b >= 8 && $b[2] == 0x42 && $b[3] == 0x12;
    return $self->_yamaha($at, @b)    if $b[0] == 0x43 && @b >= 7 && ($b[1] & 0xf0) == 0x10 && $b[2] == 0x4c;
    return;
}

# Universal messages: GM System On and Off, GM2 On (non-real time 09 01-03);
# the master's volume, balance and tuning (real time 04); GM2's controller
# destinations (real time 09).
sub _universal ($self, $at, @b) {
    my $master = $self->{master};
    my $word   = sub ($i) { ($b[$i + 1] // 0) * 128 + ($b[$i] // 0) };

    if ($b[0] == 0x7e && $b[2] == 0x09 && $b[3] >= 1 && $b[3] <= 3) {
        $self->reset_channels($at);
    }
    elsif ($b[0] == 0x7f && $b[2] == 0x04) {
        if    ($b[3] == 1) { $master->{volume}  = $word->(4) / 16383 }
        elsif ($b[3] == 2) { $master->{balance} = ($word->(4) - 8192) / 8192 }
        elsif ($b[3] == 3) { $master->{fine}    = ($word->(4) - 8192) / 8192 }
        elsif ($b[3] == 4) { $master->{coarse}  = ($b[5] // 64) - 64 }
    }
    elsif ($b[0] == 0x7f && $b[2] == 0x09 && @b >= 5 && $b[3] >= 1 && $b[3] <= 3) {
        $self->_destination(@b[ 3 .. $#b ]);
    }
    return;
}

# Roland GS (DT1 to a GS device): the reset, the master's volume and
# coarse tuning, a part made a drum part.
sub _roland ($self, $at, @b) {
    my ($a1, $a2, $a3, $v) = @b[ 4 .. 7 ];
    return if $a1 != 0x40;

    if    ($a2 == 0x00 && $a3 == 0x7f) { $self->reset_channels($at) }
    elsif ($a2 == 0x00 && $a3 == 0x04) { $self->{master}{volume} = $v / 127 }
    elsif ($a2 == 0x00 && $a3 == 0x05) { $self->{master}{coarse} = $v - 64 }
    elsif (($a2 & 0xf0) == 0x10 && $a3 == 0x15) {
        my $c = $self->{channels}[ $GS_PART[ $a2 & 0x0f ] ];
        $self->_notes_off($c, $at);
        $c->{drum} = $v ? 1 : 0;
    }
    return;
}

# Yamaha XG (parameter change): the reset, the master's volume, a part made
# a drum part.
sub _yamaha ($self, $at, @b) {
    my ($a1, $a2, $a3, $v) = @b[ 3 .. 6 ];

    if    ($a1 == 0 && $a2 == 0 && $a3 == 0x7e) { $self->reset_channels($at) }
    elsif ($a1 == 0 && $a2 == 0 && $a3 == 0x04) { $self->{master}{volume} = $v / 127 }
    elsif ($a1 == 0x08 && $a2 < 16 && $a3 == 0x07) {
        my $c = $self->{channels}[$a2];
        $self->_notes_off($c, $at);
        $c->{drum} = $v ? 1 : 0;
    }
    return;
}

# GM2's controller destination setting (universal real-time 09): a source
# (1 channel pressure, 2 key pressure, 3 a controller, 1-31 or 64-95) of a
# channel, given [parameter, range] pairs: 0 pitch (40-88: -24 .. +24
# semitones), 1 the filter's cutoff (-9600 .. +9450 cents), 2 amplitude
# (0 .. 127/64 times), 3, 4, 5 the LFO's depth on pitch (0 .. 600 cents),
# on the cutoff (0 .. 2400 cents), on amplitude (0 .. 100 %); each at full
# from the source at 127. The ranges not sent are their defaults: 64, 64,
# 64, 0, 0, 0 (nothing).
my @DEST_DEFAULT = (64, 64, 64, 0, 0, 0);

sub _destination ($self, $kind, $channel, @pairs) {
    my $c = $self->{channels}[$channel] // return;

    my $source;
    if    ($kind == 1) { $source = 'chp' }
    elsif ($kind == 2) { $source = 'kp' }
    else {
        $source = shift @pairs // return;
        return if !($source >= 1 && $source <= 31 || $source >= 64 && $source <= 95);
    }

    my $d = $c->{dest}{$source} //= [@DEST_DEFAULT];
    while (@pairs >= 2) {
        my ($parameter, $range) = splice @pairs, 0, 2;
        next if $parameter > 5;
        if ($parameter == 0) {
            $range = 40 if $range < 40;
            $range = 88 if $range > 88;
        }
        $d->[$parameter] = $range;
    }
    return;
}

# A destination's ranges in the units the voices take, at full: semitones,
# octaves of cutoff, amplitude less 1, cents, cents, the amplitude's depth.
sub _dest_units ($d) {
    return ($d->[0] - 64, ($d->[1] - 64) / 8, $d->[2] / 64 - 1, $d->[3] * 600 / 127, $d->[4] * 2400 / 127, $d->[5] / 127);
}

# What a channel's destinations come to now, from its pressure and
# controllers (key pressure is the voices'): [pitch (semitones), cutoff
# (octaves), amplitude (a factor), the LFO's pitch depth (cents), cutoff
# depth (cents), amplitude depth (0 .. 1)]; undef where none is set.
sub _destinations ($c) {
    my $dest    = $c->{dest};
    my @sources = grep { $_ ne 'kp' } keys %$dest;
    return undef if !@sources;

    my @sum = (0.0, 0.0, 1.0, 0.0, 0.0, 0.0);
    for my $source (@sources) {
        my $v = $source eq 'chp' ? $c->{pressure} : ($c->{cc}{$source} // 0) / 127;
        my @u = _dest_units($dest->{$source});
        $sum[$_] += $v * $u[$_] for 0, 1, 3, 4, 5;
        $sum[2] *= 1 + $v * $u[2];
    }
    return \@sum;
}

# The channel's gains: left, right (constant power) and reverb send; its
# level and pan (-1 .. 1).
sub _gains ($self, $c) {
    my $level = ($c->{volume} / 127)**2 * ($c->{expression} / 127)**2;
    my $pan   = $c->{pan} <= 64 ? ($c->{pan} - 64) / 64 : ($c->{pan} - 64) / 63;
    my ($l, $r) = Peta::Synth::Voice::pan_law($pan);
    return ($level * $l, $level * $r, $level * $c->{send} / 127, $level, $pan);
}

# The next $n samples ($n a multiple of 64), as two strings of packed floats.
sub render ($self, $n) {
    my ($left, $right) = $self->render_arrays($n);
    return (pack('f*', @$left), pack('f*', @$right));
}

# A whole sound: the next $frames samples, rendered in quanta of $quantum
# (the rest of the last quantum is dropped).
sub render_frames ($self, $frames, $quantum = 512) {
    my (@left, @right);
    while (@left < $frames) {
        my ($l, $r) = $self->render_arrays($quantum);
        push @left,  @$l;
        push @right, @$r;
    }
    $#left = $#right = $frames - 1;
    return (\@left, \@right);
}

# What a channel is, at a block's edge, for its voices' controls (see
# Peta::Synth::Voice::controls): each an array over the quantum's edges.
my @EDGE_FIELDS = qw(gl gr gs lv pn bend mod wheel breath foot chp cc74 cc71);

# The next $n samples ($n a multiple of 64), as two array references.
sub render_arrays ($self, $n) {
    my $B  = BLOCK;
    my $nb = $n / $B;
    die "a quantum is a multiple of $B samples\n" if $nb != int $nb;

    my $rate  = $self->{rate};
    my $now   = $self->{now};
    my $queue = $self->{queue};
    $self->{until} = $now + $n;
    $self->_arpeggiate($now, $now + $n) if @{ $self->{arps} };

    # Silence, while nothing sounds and nothing is about to: no voice, no
    # event in this quantum, the reverb and the equalizer rung out, the
    # limiter open.
    if (!@{ $self->{active} } && !(@$queue && $queue->[0][0] < $now + $n - $B / 2) && $self->_at_rest) {
        $self->{reverb}->clear;
        $self->{eq}->clear;
        $self->{now} = $now + $n;
        delete $self->{held_back};
        return ([ (0.0) x $n ], [ (0.0) x $n ]);
    }

    $_->{first} = 0 for @{ $self->{active} };

    # The events, block by block. What the channels are changes only after
    # an event: from edge j on, as $state (the channels' states, made again
    # after an event).
    my @runs;    # [ the first edge, the states from it ]
    for my $j (0 .. $nb) {
        if ($j < $nb) {
            my $edge = $now + $j * $B;
            while (@$queue && $queue->[0][0] < $edge + $B / 2) {
                my ($at, $event) = @{ shift @$queue };
                my $before = @{ $self->{active} };
                $self->_apply($event, $edge);
                $_->{first} = $j for @{ $self->{active} }[ $before .. $#{ $self->{active} } ];
            }
        }
        my $state = $self->{state} //= [ map { $self->_channel_state($_) } @{ $self->{channels} } ];
        push @runs, [ $j, $state ] if !@runs || $runs[-1][1] != $state;
    }
    my @snap = map { _edges($_, \@runs, $nb) } 0 .. 15;

    # The vibrato's rate, depth and delay (CC76-78), the modulation range and
    # key pressure's destinations, as they are at the quantum's end.
    for my $number (0 .. 15) {
        my $c     = $self->{channels}[$number];
        my $sound = $c->{sound};
        my $s     = $snap[$number];
        $s->{vrate}    = 2**(($sound->{76} - 64) / 32);
        $s->{vdepth}   = 2**(($sound->{77} - 64) / 16);
        $s->{vdelay}   = 2**(($sound->{78} - 64) / 32);
        $s->{modrange} = $c->{mod_range};
        $s->{kp}       = [ _dest_units($c->{dest}{kp}) ] if $c->{dest}{kp};
    }

    my $active = $self->{active};
    $_->controls($now, $nb, $B, $snap[ $_->{channel} ]) for @$active;

    my $stats = $self->{stats};
    $stats->{peak_voices} = @$active if @$active > $stats->{peak_voices};
    for my $voice (@$active) {
        $stats->{voice_blocks}   += $nb - $voice->{first};
        $stats->{partial_blocks} += ($nb - $voice->{first}) * @{ $voice->{ratio} };
    }

    # The reverb where the engine can run it (on the card), else here; not at
    # all while it has rung out and no voice sends to it.
    my $engine = $self->{engine};
    my ($dry_left, $dry_right, $send, $wet_left, $wet_right);
    if ($self->{reverb}->quiet && !grep { grep { $_ != 0 } @{ $_->{gs} } } @$active) {
        $self->{reverb}->clear;
        ($dry_left, $dry_right, $send) = $engine->render($active, $n, $rate);
    }
    elsif ($engine->can('render_reverb')) {
        ($dry_left, $dry_right, $send, $wet_left, $wet_right) = $engine->render_reverb($active, $n, $rate, $self->{reverb});
    }
    else {
        ($dry_left, $dry_right, $send) = $engine->render($active, $n, $rate);
        ($wet_left, $wet_right) = $self->{reverb}->process($send);
    }
    my ($left, $right) = $self->_master($n, $dry_left, $dry_right, $wet_left // $send, $wet_right // $send, $wet_left ? 1.0 : 0.0);

    $self->{now} = $now + $n;
    my $end = $self->{now};

    # The fidelity: a voice fallen under its quiet fades out (each voice
    # looked at every eighth quantum).
    if (my $quiet = $FIDELITY{ $self->{fidelity} }{quiet}) {
        my $level = 10**($quiet / 20);
        my $turn  = $self->{turn}++ % 8;
        for my $i (grep { $_ % 8 == $turn } 0 .. $#$active) {
            my $voice = $active->[$i];
            $voice->kill($end) if !defined $voice->{killed} && $voice->under(($end - $voice->{start}) / $rate, $level);
        }
    }
    $self->_keep([ grep { !$_->done(($end - $_->{start}) / $rate) } @$active ]);
    return ($left, $right);
}

sub _at_rest ($self) {
    return $self->{reverb}->quiet && $self->{eq}->quiet && (!$self->{limiter} || $self->{limit} == 1.0);
}

# Channel $number at the quantum's edges, from the runs of its states: an
# array of $nb + 1 for each of @EDGE_FIELDS; and the controller
# destinations' six, where any of the runs has them (the default where one
# has not).
sub _edges ($number, $runs, $nb) {
    my %s;
    for my $r (0 .. $#$runs) {
        my ($from, $state) = @{ $runs->[$r] };
        my $count = ($r < $#$runs ? $runs->[$r + 1][0] : $nb + 1) - $from;
        my $v     = $state->[$number];
        push @{ $s{$_} }, ($v->{$_}) x $count for @EDGE_FIELDS;
    }
    if (grep { $_->[1][$number]{dest} } @$runs) {
        for my $r (0 .. $#$runs) {
            my ($from, $state) = @{ $runs->[$r] };
            my $count = ($r < $#$runs ? $runs->[$r + 1][0] : $nb + 1) - $from;
            my $d     = $state->[$number]{dest} // [ 0.0, 0.0, 1.0, 0.0, 0.0, 0.0 ];
            push @{ $s{dest}[$_] }, ($d->[$_]) x $count for 0 .. 5;
        }
    }
    return \%s;
}

# A channel as its voices see it: its gains, level and pan; the bend with
# the tunings (semitones); the modulation wheel and the pressure as cents
# of vibrato (unless a controller destination says what they do); as
# sources of modulation, the wheel, breath, foot, pressure (0 .. 1),
# brightness and resonance (-1 .. 1); the controller destinations.
sub _channel_state ($self, $c) {
    my $master = $self->{master};
    my ($gl, $gr, $gs, $lv, $pn) = $self->_gains($c);
    my $mod = ($c->{dest}{1} ? 0 : $c->{mod}) + ($c->{dest}{chp} ? 0 : $c->{pressure});

    return {
        gl     => $gl,
        gr     => $gr,
        gs     => $gs,
        lv     => $lv,
        pn     => $pn,
        bend   => $c->{bend} * $c->{range} + $c->{tune} + ($master->{coarse} + $master->{fine}),
        mod    => $c->{mod_range} * ($mod > 1 ? 1 : $mod),
        wheel  => $c->{mod},
        breath => $c->{breath},
        foot   => $c->{foot},
        chp    => $c->{pressure},
        cc74   => ($c->{sound}{74} - 64) / 64,
        cc71   => ($c->{sound}{71} - 64) / 64,
        dest   => _destinations($c),
    };
}

# The voices still sounding; those that are done leave the channels' lists too.
sub _keep ($self, $active) {
    my $before = $self->{active};
    $self->{active} = $active;
    return if @$active == @$before;

    my %alive = map { $_ => 1 } @$active;
    for my $c (@{ $self->{channels} }) {
        for my $key (keys %{ $c->{held} }) {
            my @still = grep { $alive{$_} } @{ $c->{held}{$key} };
            if (@still) { $c->{held}{$key} = \@still } else { delete $c->{held}{$key} }
        }
        $c->{pedal} = [ grep { $alive{$_} } @{ $c->{pedal} } ];
    }
    return;
}

# What the scheduled events will sound, without sounding them: every voice
# they start, with the second it starts, the second it will be silent
# ('inf': never) and its channel's program (undef on the drums). Event by
# event as rendering takes them; before each, the voices silent by then
# go (Peta::Synth::Voice's ends: rendering finds them done at the end of
# the quantum after). The queue is used up. For planning: see
# Peta::Synth::Profile.
sub foresee ($self) {
    my $rate  = $self->{rate};
    my $queue = $self->{queue};
    my %program;    # what each voice was started with
    my @voices;
    my $close = sub ($voice) {
        my $ends  = $voice->ends;
        my $start = $voice->{start} / $rate;
        push @voices, {
            voice   => $voice,
            program => delete $program{$voice},
            start   => $start,
            end     => $ends eq 'inf' ? 'inf' : $start + $ends,
        };
    };

    while (@$queue) {
        my ($at, $event) = @{ shift @$queue };

        my (@keep, @gone);
        for my $voice (@{ $self->{active} }) {
            my $ends = $voice->ends;
            if ($ends ne 'inf' && $voice->{start} + $ends * $rate <= $at) { push @gone, $voice } else { push @keep, $voice }
        }
        $close->($_) for @gone;
        $self->_keep(\@keep);

        my $before = @keep;
        $self->_apply($event, $at);
        my $active = $self->{active};
        for my $voice (@$active[ $before .. $#$active ]) {
            my $c = $self->{channels}[ $voice->{channel} ];
            $program{$voice} = $c->{drum} ? undef : $c->{program};
        }
        $self->{now} = $at;
    }

    $close->($_) for @{ $self->{active} };
    $self->_keep([]);
    return [ sort { $a->{start} <=> $b->{start} } @voices ];
}

# Dry and wet summed, the master gain, and a limiter that reacts within a
# block and lets go over a quarter of a second; into fresh arrays (which is
# what pperl's JIT compiles).
sub _master ($self, $n, $dry_left, $dry_right, $wet_left, $wet_right, $wet) {
    my $B       = BLOCK;
    my $master  = $self->{master};
    my $gain    = $self->{gain} * $master->{volume};
    my $balance = $master->{balance};
    my $gain_l  = $balance > 0 ? $gain * (1 - $balance) : $gain;
    my $gain_r  = $balance < 0 ? $gain * (1 + $balance) : $gain;

    my @left  = (0.0) x $n;
    my @right = (0.0) x $n;
    for my $i (0 .. $n - 1) {
        $left[$i]  = $gain_l * ($dry_left->[$i] + $wet * $wet_left->[$i]);
        $right[$i] = $gain_r * ($dry_right->[$i] + $wet * $wet_right->[$i]);
    }
    if ($self->{eq}->active) {
        my ($l, $r) = $self->{eq}->process(\@left, \@right);
        @left  = @$l;
        @right = @$r;
    }
    return (\@left, \@right) if !$self->{limiter};

    # The limiter: each block's peak brought under 0.98, the gain moving
    # linearly across a block, and a block ahead: the sound goes out a block
    # late (the last one held back till the next quantum), so that the gain
    # is down by the time a peak comes, not on its way down as it passes.
    my $held = $self->{held_back} // [ [ (0.0) x $B ], [ (0.0) x $B ] ];
    unshift @left,  @{ $held->[0] };
    unshift @right, @{ $held->[1] };
    my $nb = $n / $B;
    my @target;
    for my $j (0 .. $nb) {
        my $peak = 0.0;
        for my $i ($j * $B .. $j * $B + $B - 1) {
            my $x = abs($left[$i]);
            $peak = $x if $x > $peak;
            $x = abs($right[$i]);
            $peak = $x if $x > $peak;
        }
        $target[$j] = $peak > 0.98 ? 0.98 / $peak : 1.0;
    }
    my $limit   = $self->{limit};
    my $recover = exp(-$B / (0.25 * $self->{rate}));
    for my $j (0 .. $nb - 1) {
        my $next = 1.0 - (1.0 - $limit) * $recover;
        $next = $target[$j]     if $target[$j] < $next;
        $next = $target[ $j + 1 ] if $target[ $j + 1 ] < $next;
        next if $limit == 1.0 && $next == 1.0;

        my $step = ($next - $limit) / $B;
        my $g    = $limit;
        for my $i ($j * $B .. $j * $B + $B - 1) {
            $left[$i]  *= $g;
            $right[$i] *= $g;
            $g += $step;
        }
        $limit = $next;
    }
    $self->{limit} = $limit;
    $self->{held_back} = [ [ splice @left, $n ], [ splice @right, $n ] ];
    return (\@left, \@right);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Synth - the synthesizer: channels, voices, engine, reverb

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $synth = Peta::Synth::Synth->new(rate => 48000, partials => 48);
    $synth->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
    my ($left, $right) = $synth->render(4800);     # 0.1 s, packed floats

    $synth->schedule(Peta::Synth::MIDI->read('song.mid')->timeline);
    while ($synth->busy) {
        my ($l, $r) = $synth->render(1024);
        ...
    }

=head1 DESCRIPTION

A running synthesizer of sixteen MIDI channels. It takes events now
(L</play>) or at a time (L</schedule>), and renders quanta of samples. Notes
of channel 10, and of a channel with bank 120 or 127, are drums. What MIDI it
understands (controllers, RPN and NRPN, system exclusive, mono mode) is
listed with the channel's fields above C<_channel> in the source and in
doc/midi.md.

=head1 METHODS

=head2 new

C<< new(rate => 48000, partials => 48, voices => 256, fidelity => 'high', gain => 0.3, limiter => 1, engine => $engine, reverb => {...}, waves => 1) >>.
C<partials> is the most partials a voice has, C<voices> the most voices at
once (the quietest ending ones are stolen first). C<fidelity> (C<low>,
C<mid>, C<high>) is what may be left out that
is hardly heard, for playing on a machine that cannot keep up: a voice
that has fallen 60 dB (mid) or 45 dB (low) under its full level fades out
in 5 ms and ends, not at 80 dB, and low plays at most 48 voices at once.
High leaves nothing out. The engine defaults to the
fastest there is (L<Peta::Synth::Engine>). C<waves>: harmonic partials are
read from wave sequences (L<Peta::Synth::Wavetable>), made as notes need
them and kept; a store of them can be given (made ahead, shared); 0 turns
every partial one by one. By default as the engine fares better (its
C<reads_waves>: the GPU engine turns partials, the others read tables).

=head2 waves

The store of wave sequences (L<Peta::Synth::Wavetable>), or undef.

=head2 play

An event (as L<Peta::Synth::MIDI> has them) now.

=head2 by_hand, held, let_go, forget_held

C<by_hand($event)>: an event played by hand (the page, MIDI played live),
now; what it sets is held against the other MIDI (a file's): the
instrument (bank select and program change), the mixer's controllers
(volume, pan, the sends, portamento time, the sound controllers), the
arpeggiator's settings (also as an event: C<< { type => 'arp', channel, name,
value } >>). What is played (notes, the wheels, expression, pedals) is not
held. While a setting is held, the file's events for it are kept aside, the
last of each, and a reset from the file keeps it; a reset played by hand
lets go of everything. C<held($channel)>: what the channel holds, by name
(C<program>, C<cc 7>, C<arp mode>). C<let_go($channel, $name)>: a setting
let go (without a name, all the channel's), as the file has it by then.
C<forget_held>: nothing held, the settings left as they are.

=head2 schedule

C<schedule(\@events, $offset, $from)>: events with a C<time> in seconds,
from now plus C<$offset>, in any order (those at the same time in the order
given). With C<$from>, from that many seconds into them: the events before
it but the notes (programs, controllers, bends, system exclusive) are
applied at once, in their order, so that the channels are as the file has
them there. Before that, C<reset_channels> (below).

=head2 render, render_arrays

C<render($n)>: the next C<$n> samples (a multiple of 64) as left and right
strings of packed floats; C<render_arrays> gives them as array references.

=head2 render_frames

C<render_frames($frames, $quantum = 512)>: a whole sound, the next C<$frames>
samples as array references, rendered in quanta of C<$quantum> (the rest of
the last one is dropped).

=head2 foresee

What the scheduled events will sound, without sounding them: every voice
they start, with the second it starts, the second it will be silent
(C<inf>: never) and its channel's program (undef on the drums); the queue
is used up. For planning: L<Peta::Synth::Profile>.

=head2 pending, active

Events still scheduled, and voices sounding.

=head2 busy

Whether anything is left to render: events, voices, or the reverb's tail.

=head2 stop, panic, reset, reset_channels

C<stop>: drop what is scheduled and release every voice. C<panic>: the same,
and silence within milliseconds. C<reset>: every channel to its defaults,
every voice gone at once, nothing held. C<reset_channels>: every channel
and the master to their defaults as a MIDI reset sets them, the voices that
sound let go (as their channels then have them); the mutes stay, and what
is held by hand (see C<by_hand>).

=head2 channel

C<channel($number)>: the state of a channel, 0 .. 15 (a hash; its C<mute>
may be set).

=head2 program_patch, drum_patch, restore_patch

C<program_patch($program, $bank)>, C<drum_patch($key, $kit)>: the synth's
own patch of a program (or of its variation, by GS bank) or of a drum key
(in a kit; a key the kit does not have as its own is the standard kit's);
its fields can be changed while the synth runs. C<restore_patch('program'
or 'drum', $n, $bank)> goes back to the default.

A program change picks the variation of the bank selected before it
(L<Peta::Synth::Patch/variation>), and on a drum channel the kit
(L<Peta::Synth::Patch/kit>); the channel keeps them as C<variation> and
C<kit>.

=head2 edits, apply_edits

C<edits>: what has been changed from the default patches, as a bank
(C<< { programs => { 0 => { cutoff => 3000 }, '8:4' => {...} }, drums => { 38 => {...}, '40:38' => {...} } } >>:
a variation or a kit's own key as C<bank:number>), which C<apply_edits($bank)>
applies to a synth.

=head2 set

C<set($name, $value)>: C<partials>, C<voices>, C<fidelity>, C<gain> or C<limiter>.

=head2 account, load, adapt

For playing as it renders: C<account($seconds, $samples)> after each
render, what it took; C<load> the smoothed share of real time the
rendering takes; C<adapt($most)> gives new notes fewer partials when the
load is high, more (up to C<$most>) when it is low.

=head2 arpeggiator, set_arpeggiator

C<arpeggiator($channel)>: a channel's arpeggiator
(L<Peta::Synth::Arpeggiator>). While it is on, the channel's keys go to it
and it plays them, its notes queued a quantum ahead (its first at once).
C<< set_arpeggiator($channel, on => 1, mode => 'updown', ...) >> changes
its own settings (the page's, a bank's); turned off, what it plays is let
go. What MIDI sets (a file's NRPN, CC 80 and 81, tempo) lasts until a
reset or a file played from a point (C<reset_channels>): then it is its
own settings again. The own settings are saved with the bank.

=head2 channel_eq, set_channel_eq

C<channel_eq($channel)>: a channel's equalizer (L<Peta::Synth::EQ>, its
response used as gains on the partials of the channel's voices).
C<< set_channel_eq($channel, band => { freq, gain, q }, ...) >> changes it,
for the voices that sound too. Saved with the bank; a reset leaves it.

=head2 rate, now, engine, reverb, eq, stats

The sample rate, the sample the next quantum starts at, the engine, the
reverb, the master equalizer (L<Peta::Synth::EQ>), and counts of what has
been rendered.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

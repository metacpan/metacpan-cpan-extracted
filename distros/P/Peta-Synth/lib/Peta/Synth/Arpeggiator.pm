package Peta::Synth::Arpeggiator;
# ABSTRACT: the keys held, played one after another in a pattern

# An arpeggiator: the keys held on a channel played one after another, in a
# pattern, in time, as hardware synthesizers have it. It hears the
# channel's keys (press, release) and gives the notes to play as events at
# sample times (events): a note on at each step, its note off a gate later.
#
# The patterns are those of Music::MelodicDevice::Arpeggiation (up, down,
# updown, random, converge, diverge, pedal_up, pedal_down, pedal_updown),
# and besides downup, played (in the order the keys came) and chord (every
# key at each step). Over more octaves the keys are repeated an octave up,
# and again. Latched, the keys go on after they are let go, until the next
# chord is pressed.
#
#   on       0 or 1
#   mode     the pattern
#   rate     steps a beat: 1/4, 1/8, 1/8T (triplets), 1/16, 1/16T, 1/32
#   tempo    beats a minute
#   octaves  1 .. 4
#   gate     a note's length, a share of its step
#   swing    every second step later by this share of a step (0 .. 0.5),
#            the first longer as much
#   latch    0 or 1

use v5.36;

our $VERSION = '0.2610180';

my @MODES = qw(up down updown downup random played chord converge diverge pedal_up pedal_down pedal_updown);
my %RATE  = ('1/4' => 1, '1/8' => 2, '1/8T' => 3, '1/16' => 4, '1/16T' => 6, '1/32' => 8);
my @RATES = ('1/4', '1/8', '1/8T', '1/16', '1/16T', '1/32');

# The settings an editor shows: name, min, max, scale (lin, int, choice), its choices.
my @FIELDS = (
    [ on      => 0,    1,     'int' ],
    [ mode    => 'up', 'pedal_updown', 'choice', [@MODES] ],
    [ rate    => '1/4', '1/32', 'choice', [@RATES] ],
    [ tempo   => 30,   300,   'lin' ],
    [ octaves => 1,    4,     'int' ],
    [ gate    => 0.05, 1,     'lin' ],
    [ swing   => 0,    0.5,   'lin' ],
    [ latch   => 0,    1,     'int' ],
);
my %DEFAULT = (on => 0, mode => 'up', rate => '1/16', tempo => 120, octaves => 1, gate => 0.5, swing => 0, latch => 0);

sub field_info () {
    return [ map {
        my ($name, $min, $max, $scale, $choices) = @$_;
        +{ name => $name, min => $min, max => $max, scale => $scale, $choices ? (choices => $choices) : () };
    } @FIELDS ];
}

sub defaults () { return {%DEFAULT} }

# Steered by MIDI: NRPN 0x7D (125), its LSB the setting, data entry its
# value (CC6, and CC38 for tempo's low seven bits): 0 on (64 and up), 1 the
# pattern (0 .. 11, as @MODES has them), 2 the rate (0 .. 5, as @RATES), 3
# the tempo (beats a minute, 14 bits), 4 octaves, 5 gate (0 .. 127 of a
# step), 6 swing (0 .. 127 of half a step), 7 latch (64 and up). A setting
# as (name => value); none for what is out of range.
use constant NRPN => 0x7d;

sub nrpn ($setting, $msb, $lsb = 0) {
    my $clamp = sub ($v, $lo, $hi) { $v < $lo ? $lo : $v > $hi ? $hi : $v };
    return (on => $msb >= 64 ? 1 : 0)                                  if $setting == 0;
    return $MODES[$msb] ? (mode => $MODES[$msb]) : ()                  if $setting == 1;
    return $RATES[$msb] ? (rate => $RATES[$msb]) : ()                  if $setting == 2;
    return (tempo => $clamp->(128 * $msb + $lsb, 30, 300))             if $setting == 3;
    return (octaves => $clamp->($msb, 1, 4))                           if $setting == 4;
    return (gate => $clamp->($msb / 127, 0.05, 1))                     if $setting == 5;
    return (swing => $msb / 127 * 0.5)                                 if $setting == 6;
    return (latch => $msb >= 64 ? 1 : 0)                               if $setting == 7;
    return;
}

# new(rate => samples a second, channel => 0 .. 15, settings => {...}).
sub new ($class, %arg) {
    my $self = bless {
        srate    => $arg{rate} // 48000,
        channel  => $arg{channel} // 0,
        set      => {%DEFAULT},
        held     => [],       # the keys held (or latched): [key, velocity, held down], in the order pressed
        pattern  => undef,    # the steps, made again when the keys change
        step     => 0,        # the next step's place in the pattern
        count    => 0,        # steps played since the keys began (for the swing)
        next     => undef,    # the next step's sample; undef: stopped
        offs     => [],       # the notes sounding: [sample of their off, key]
        seed     => 12345,
    }, $class;
    $self->set(%{ $arg{settings} // {} });
    return $self;
}

sub on ($self) { return $self->{set}{on} }

sub params ($self) { return { %{ $self->{set} } } }

# Settings changed; an unknown one dies. Turned off, what it plays is let
# go (see stop); the latch let go, the keys no longer held down are
# forgotten.
sub set ($self, %fields) {
    for my $name (keys %fields) {
        die "the arpeggiator has no '$name'\n" if !exists $DEFAULT{$name};
        my $value = $fields{$name};
        die "'$value' is no arpeggiator mode\n" if $name eq 'mode' && !grep { $_ eq $value } @MODES;
        die "'$value' is no arpeggiator rate\n" if $name eq 'rate' && !$RATE{$value};
        $self->{set}{$name} = $value;
    }
    @{ $self->{held} } = grep { $_->[2] } @{ $self->{held} } if exists $fields{latch} && !$fields{latch};
    $self->{pattern} = undef;
    $self->{step}    = 0 if exists $fields{mode} || exists $fields{octaves};    # a new pattern from its start
    return $self;
}

# How long the first step waits for the other keys of a chord (seconds).
use constant CHORD => 0.01;

# A key pressed: into the chord (a latched chord let go is replaced by the
# next one pressed); the first starts the steps, 10 ms after it (the
# chord's other keys).
sub press ($self, $key, $velocity, $at) {
    $self->{held} = [] if $self->{set}{latch} && !grep { $_->[2] } @{ $self->{held} };
    @{ $self->{held} } = grep { $_->[0] != $key } @{ $self->{held} };
    push @{ $self->{held} }, [ $key, $velocity, 1 ];
    $self->{pattern} = undef;
    if (!defined $self->{next}) {
        @$self{qw(next step count)} = ($at + int(CHORD * $self->{srate}), 0, 0);
    }
    return;
}

# A key let go: out of the chord, unless latched.
sub release ($self, $key, $at) {
    my ($note) = grep { $_->[0] == $key } @{ $self->{held} } or return;
    $note->[2] = 0;
    return if $self->{set}{latch};
    @{ $self->{held} } = grep { $_->[0] != $key } @{ $self->{held} };
    $self->{pattern} = undef;
    return;
}

# Every key forgotten and what sounds let go now: [sample, event] for the
# note offs.
sub stop ($self, $at) {
    my @events = map { [ $at, $self->_off($_->[1]) ] } @{ $self->{offs} };
    @$self{qw(held pattern next offs marked)} = ([], undef, undef, [], 0);
    return @events;
}

# What is due in [$from, $to) (samples): the note offs, and a mark for the
# next step ({ type => 'arp_step', channel }), whose notes are chosen when
# it comes (step), of the keys held then. [sample, event], in time order.
sub events ($self, $from, $to) {
    my @events = $self->_due_offs($to, 1);
    if (defined $self->{next} && !$self->{marked} && $self->{next} < $to) {
        push @events, [ $self->{next} < $from ? $from : $self->{next}, { type => 'arp_step', channel => $self->{channel} } ];
        $self->{marked} = 1;
    }
    return sort { $a->[0] <=> $b->[0] } @events;    # sort is stable: offs before a step of their sample
}

# The step marked, played at $at: its notes on, [sample, event] (their note
# offs kept for events). With no key held, the steps stop.
sub step ($self, $at) {
    $self->{marked} = 0;
    return if !defined $self->{next};
    if (!@{ $self->{held} }) {
        $self->{next} = undef;
        return;
    }

    my $length = $self->{srate} * 60 / $self->{set}{tempo} / $RATE{ $self->{set}{rate} };
    my $swing  = $self->{set}{swing} * ($self->{count} % 2 ? -1 : 1);
    my $off    = $at + _max(1, int($self->{set}{gate} * $length + 0.5));
    my @ons;
    for my $note ($self->_notes) {
        my ($key, $velocity) = @$note;
        push @ons, [ $at, { type => 'note_on', channel => $self->{channel}, key => $key, velocity => $velocity, arp => 1 } ];
        push @{ $self->{offs} }, [ $off, $key ];
    }
    $self->{next} += $length * (1 + $swing);
    $self->{count}++;
    return @ons;
}

# What it plays in [$from, $to) on its own, not in a synthesizer: the note
# events, [sample, event], in time order.
sub play ($self, $from, $to) {
    my @played;
    while (my @events = $self->events($from, $to)) {
        push @played, map { $_->[1]{type} eq 'arp_step' ? $self->step($_->[0]) : $_ } @events;
    }
    return sort { $a->[0] <=> $b->[0] } @played;
}

sub _max ($a, $b) { return $a > $b ? $a : $b }

sub _off ($self, $key) { return { type => 'note_off', channel => $self->{channel}, key => $key, arp => 1 } }

# The note offs due: at a step, those at it or before (so that a note
# ends before the same key begins again); at the end, those before it.
sub _due_offs ($self, $at, $before_only = 0) {
    my (@due, @later);
    for my $off (@{ $self->{offs} }) {
        my $due = $before_only ? $off->[0] < $at : $off->[0] <= $at;
        if ($due) { push @due, [ $off->[0], $self->_off($off->[1]) ] }
        else      { push @later, $off }
    }
    $self->{offs} = \@later;
    return @due;
}

# The step's notes: [key, velocity], one but in chord mode.
sub _notes ($self) {
    my $pattern = $self->{pattern} //= $self->_pattern;
    my $mode    = $self->{set}{mode};
    return @{ $pattern->[0] } if $mode eq 'chord';

    my $place = $mode eq 'random' ? int($self->_random * @$pattern) : $self->{step} % @$pattern;
    $self->{step}++;
    return $pattern->[$place];
}

# The pattern of the keys held: the notes in the order they are played (a
# step each; in chord mode one step of them all).
sub _pattern ($self) {
    my $set   = $self->{set};
    my @keys  = $set->{mode} eq 'played' ? @{ $self->{held} } : sort { $a->[0] <=> $b->[0] } @{ $self->{held} };
    my @notes = map {
        my $up = 12 * $_;
        map { [ $_->[0] + $up, $_->[1] ] } grep { $_->[0] + $up <= 127 } @keys;
    } 0 .. $set->{octaves} - 1;
    return [ \@notes ] if $set->{mode} eq 'chord';

    my $mode = $set->{mode};
    my $last = $#notes;
    return [@notes]                                         if $mode eq 'up' || $mode eq 'played' || $mode eq 'random' || $last < 1;
    return [ reverse @notes ]                               if $mode eq 'down';
    return [ @notes, reverse @notes[ 1 .. $last - 1 ] ]     if $mode eq 'updown';
    return [ reverse(@notes), @notes[ 1 .. $last - 1 ] ]    if $mode eq 'downup';
    return [ _converge(@notes) ]                            if $mode eq 'converge';
    return [ reverse _converge(@notes) ]                    if $mode eq 'diverge';
    my @pedal_up   = map { ($notes[0], $notes[$_]) } 1 .. $last;
    my @pedal_down = map { ($notes[-1], $notes[ $last - $_ ]) } 1 .. $last;
    return \@pedal_up                                       if $mode eq 'pedal_up';
    return \@pedal_down                                     if $mode eq 'pedal_down';
    return [ @pedal_up, @pedal_down[ 1 .. $#pedal_down ] ];    # pedal_updown
}

# From the outer notes to the middle: lowest, highest, second lowest, ...
sub _converge (@notes) {
    my @out;
    while (@notes) {
        push @out, shift @notes;
        push @out, pop @notes if @notes;
    }
    return @out;
}

sub _random ($self) {
    $self->{seed} = ($self->{seed} * 1103515245 + 12345) % 2147483648;
    return $self->{seed} / 2147483648;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Arpeggiator - the keys held, played one after another in a pattern

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $arp = Peta::Synth::Arpeggiator->new(rate => 48000, channel => 0,
        settings => { on => 1, mode => 'updown', rate => '1/16', tempo => 128, octaves => 2 });
    $arp->press(60, 100, $now);
    $arp->press(64, 100, $now);
    my @events = $arp->events($now, $now + 512);    # [sample, event], ...

=head1 DESCRIPTION

What a channel's keys play when its arpeggiator is on
(L<Peta::Synth::Synth/arpeggiator>): one note a step, in a pattern of the
keys held, at a tempo; the settings are listed at the top of the source.
The patterns are those of L<Music::MelodicDevice::Arpeggiation> (C<up>,
C<down>, C<updown>, C<random>, C<converge>, C<diverge>, C<pedal_up>,
C<pedal_down>, C<pedal_updown>), and C<downup>, C<played> (as the keys
came) and C<chord> (all of them each step). The steps begin with the first
key pressed and stop when none is held (latched: when another chord is
pressed, the last goes on).

=head1 METHODS

=head2 new

C<< new(rate => 48000, channel => 0, settings => {...}) >>.

=head2 set, params, on

C<set(%fields)> changes settings (an unknown one dies); C<params> gives them
all; C<on> whether it is on.

=head2 press, release, stop

C<press($key, $velocity, $at)> and C<release($key, $at)>, at a sample;
C<stop($at)> forgets every key and returns the note offs of what sounds.

=head2 events

C<events($from, $to)>: the notes it plays in those samples, as
C<[sample, event]> (note on and note off events, marked C<arp>).

=head2 step, play

C<step($at)>: the step C<events> marked (an C<arp_step>), played at sample
C<$at>: its notes on, [sample, event], of the keys held then (their note
offs kept for C<events>); with no key held, the steps stop.
C<play($from, $to)>: what it plays in [$from, $to) on its own, not in a
synthesizer: the note events, [sample, event], in time order.

=head2 nrpn

C<nrpn($setting, $msb, $lsb)>: the setting MIDI steers with NRPN 0x7D
(125) and data entry, as C<< (name => value) >>: 0 on, 1 the pattern (its
place in the list above, from 0), 2 the rate (1/4, 1/8, 1/8T, 1/16, 1/16T,
1/32: 0 .. 5), 3 the tempo (beats a minute, CC6 and CC38 as 14 bits), 4
octaves, 5 gate (0 .. 127 of a step), 6 swing (0 .. 127 of half a step),
7 latch; on and latch from 64.

=head2 field_info, defaults

The settings as an editor shows them (name, min, max, scale, choices), and
their defaults.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

package Peta::MIDI::Device::Out;
# ABSTRACT: a MIDI output as MIDI::RtMidi::FFI::Device::Out has it

# A MIDI output as MIDI::RtMidi::FFI::Device::Out has it: messages as
# bytes, or events encoded (Peta::MIDI::Encoder: MIDI::Stream's names and
# MIDI::Event's), and a sender for each kind of event; RPN and NRPN, and a
# panic. Out of the device's port to whoever it is connected to.

use v5.36;
use parent 'Peta::MIDI::Device';
use Carp qw(croak);
use Peta::MIDI::Encoder;

our $VERSION = '0.2610180';

sub _direction ($self) { return 'out' }

sub _build ($self, %arg) {
    $self->{encoder} = Peta::MIDI::Encoder->new(
        enable_14bit_cc       => $arg{enable_14bit_cc} // 0,
        enable_running_status => $arg{enable_running_status} // 0,
    );
    return;
}

# Messages, each its bytes.
sub send_message ($self, @messages) {
    croak 'no port is open' if !defined $self->{port};
    $self->{alsa}->send($self->{port}, $_) for @messages;
    return;
}

# An event's bytes, [ name, fields ... ] given flat or as lists of them.
sub encode_message ($self, @event) {
    return map { $self->encode_message(@$_) } @event if ref $event[0] eq 'ARRAY';
    return $self->{encoder}->encode([ $self->name_from_midi_event(shift @event), @event ]);
}
sub encode ($self, @event) { return $self->encode_message(@event) }

sub send_message_encoded ($self, @event) { return $self->send_message($self->encode_message(@event)) }
sub send_event ($self, @event)           { return $self->send_message_encoded(@event) }

# A sender for each kind of event, as send_event(name => @fields).
for my $name (qw(note_off note_on control_change patch_change key_after_touch channel_after_touch pitch_wheel_change
                 sysex clock start stop continue)) {
    no strict 'refs';
    *$name = sub ($self, @fields) { return $self->send_event($name => @fields) };
}
sub cc             ($self, @fields) { return $self->control_change(@fields) }
sub program_change ($self, @fields) { return $self->patch_change(@fields) }
sub aftertouch     ($self, @fields) { return $self->channel_after_touch(@fields) }
sub polytouch      ($self, @fields) { return $self->key_after_touch(@fields) }
sub pitch_bend     ($self, @fields) { return $self->pitch_wheel_change(@fields) }

# A registered parameter set: its number and value of 14 bits each (or
# [ coarse, fine ]; a value [ coarse ] alone sends no fine part), then the
# null parameter.
sub rpn ($self, $channel, $number, $value, $controllers = [ 101, 100 ]) {
    my ($number_coarse, $number_fine) = ref $number eq 'ARRAY' ? map { $_ // 0 } @$number[ 0, 1 ] : ($number >> 7, $number & 0x7f);
    my ($coarse, $fine) = ref $value eq 'ARRAY' ? @$value : ($value >> 7, $value & 0x7f);
    my @pairs = ($controllers->[0], $number_coarse, $controllers->[1], $number_fine, 6, $coarse);
    push @pairs, 38, $fine if defined $fine;
    push @pairs, 101, 127, 100, 127;
    return $self->cc($channel, @pairs);
}

sub nrpn ($self, $channel, $number, $value) { return $self->rpn($channel, $number, $value, [ 99, 98 ]) }

# All notes off (controller 123), on a channel or on all.
sub panic ($self, $channel = undef) {
    $self->cc($_, 123, 0) for defined $channel ? $channel : 0 .. 15;
    return;
}

# A note off for every key, on a channel or on all.
sub PANIC ($self, $channel = undef) {
    for my $ch (defined $channel ? $channel : 0 .. 15) {
        $self->note_off($ch, $_, 0) for 0 .. 127;
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Device::Out - a MIDI output as MIDI::RtMidi::FFI::Device::Out has it

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $out = Peta::MIDI::Device::Out->new(name => 'player', enable_running_status => 1);
    $out->open_port_by_name([ qr/FLUID/i, qr/TiMidity/i ]);
    $out->program_change(0, 19);
    $out->note_on(0, 60, 100);
    $out->cc(0, 7, 100, 10, 64);           # two controllers
    $out->pitch_bend(0, -2048);
    $out->rpn(0, 0, 12 << 7);              # bend range: 12 semitones
    $out->send_event(sysex => "\x7e\x7f\x09\x01");
    $out->panic;

=head1 DESCRIPTION

Messages out of the device's port (L<Peta::MIDI::Device>) to whoever it
is connected to. Events are encoded by L<Peta::MIDI::Encoder>, in
MIDI::Stream's names or MIDI::Event's.

=head1 METHODS

=head2 new

C<< new(name => ..., enable_14bit_cc => 0, enable_running_status => 0) >>.

=head2 send_message, send_message_encoded, send_event, encode_message, encode

Messages as bytes; an event (or a list of them) encoded and sent, or only
encoded.

=head2 note_on, note_off, control_change, cc, patch_change, program_change, key_after_touch, polytouch, channel_after_touch, aftertouch, pitch_wheel_change, pitch_bend, sysex, clock, start, stop, continue

Each an event's fields (C<cc>, C<program_change>, C<polytouch>,
C<aftertouch> and C<pitch_bend> MIDI::Stream's names for the others): C<note_on($channel, $note, $velocity)>,
C<cc($channel, $controller, $value, ...)>, C<pitch_bend($channel,
$value)> (-8192 .. 8191), C<sysex($bytes)>, C<clock> ...

=head2 rpn, nrpn

C<rpn($channel, $number, $value)>: the parameter and its value (14 bits,
or C<[ coarse, fine ]>), then the null parameter.

=head2 panic, PANIC

All notes off (controller 123) on a channel or all; C<PANIC> a note off
for every key.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

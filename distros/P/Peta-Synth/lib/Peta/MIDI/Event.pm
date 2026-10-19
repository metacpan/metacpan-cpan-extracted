package Peta::MIDI::Event;
# ABSTRACT: a MIDI message as an event: its name and fields

# A MIDI message as an event: its name, its fields in their order, the
# seconds since the message before it (dt), and its bytes. The names and
# fields are those of MIDI::Stream (the names MIDI::Event has besides, by
# name_to_midi_event and name_from_midi_event):
#
#   note_off, note_on   channel note velocity    (a note on of velocity 0 is a note off)
#   polytouch           channel note pressure    key_after_touch
#   control_change      channel control value
#   program_change      channel program          patch_change
#   aftertouch          channel pressure         channel_after_touch
#   pitch_bend          channel value            pitch_wheel_change (-8192 .. 8191)
#   sysex               msg                      sysex_f0 (the bytes between F0 and F7)
#   timecode            byte
#   song_position       position                 (0 .. 16383)
#   song_select         song
#   tune_request, eox (sysex_f7), clock, start, continue, stop, active_sensing,
#   system_reset        (no fields)

use v5.36;
use Exporter qw(import);

our $VERSION = '0.2610180';

our @EXPORT_OK = qw(status_byte status_name keys_for message_length split_bytes combine_bytes);

my %STATUS = (
    note_off       => 0x80, note_on        => 0x90, polytouch      => 0xa0, control_change => 0xb0,
    program_change => 0xc0, aftertouch     => 0xd0, pitch_bend     => 0xe0,
    sysex          => 0xf0, timecode       => 0xf1, song_position  => 0xf2, song_select    => 0xf3,
    tune_request   => 0xf6, eox            => 0xf7, clock          => 0xf8, start          => 0xfa,
    continue       => 0xfb, stop           => 0xfc, active_sensing => 0xfe, system_reset   => 0xff,
);
my %NAME = reverse %STATUS;

my %KEYS = (
    note_off       => [qw(channel note velocity)],
    note_on        => [qw(channel note velocity)],
    polytouch      => [qw(channel note pressure)],
    control_change => [qw(channel control value)],
    program_change => [qw(channel program)],
    aftertouch     => [qw(channel pressure)],
    pitch_bend     => [qw(channel value)],
    sysex          => [qw(msg)],
    timecode       => [qw(byte)],
    song_position  => [qw(position)],
    song_select    => [qw(song)],
);

my %MIDI_EVENT = (
    key_after_touch     => 'polytouch',
    patch_change        => 'program_change',
    channel_after_touch => 'aftertouch',
    pitch_wheel_change  => 'pitch_bend',
    sysex_f0            => 'sysex',
    sysex_f7            => 'eox',
);
my %TO_MIDI_EVENT = reverse %MIDI_EVENT;

# A name's status byte (channel 0), and a status byte's name.
sub status_byte ($name) { return $STATUS{$name} }
sub status_name ($status) { return $status < 0xf0 ? $NAME{ $status & 0xf0 } : $NAME{$status} }

# An event's fields, in order.
sub keys_for ($name) { return $KEYS{$name} // [] }

# MIDI::Event's names and back.
sub name_to_midi_event ($name)   { return $TO_MIDI_EVENT{$name} // $name }
sub name_from_midi_event ($name) { return $MIDI_EVENT{$name} // $name }

# A message's length with its status byte (0: as long as it is, system exclusive).
sub message_length ($status) {
    return 0 if $status < 0x80 || $status == 0xf0;
    return 3 if $status < 0xc0 || ($status >= 0xe0 && $status < 0xf0) || $status == 0xf2;
    return 2 if $status < 0xe0 || $status == 0xf1 || $status == 0xf3;
    return 1;
}

# A value of 14 bits as (lsb, msb), and back.
sub split_bytes ($value)        { return ($value & 0x7f, ($value >> 7) & 0x7f) }
sub combine_bytes ($lsb, $msb)  { return (($msb & 0x7f) << 7) | ($lsb & 0x7f) }

# An event from a whole message (its bytes as numbers) and the seconds
# since the one before.
sub new ($class, $message, $dt = 0) {
    my ($status, @data) = @$message;
    my $name = status_name($status) // 'unknown';
    $name = 'note_off' if $name eq 'note_on' && !$data[1];
    my %field;
    if ($status < 0xf0) {
        my @keys = @{ $KEYS{$name} };
        @field{@keys} = ($status & 0x0f, @data);
        $field{value} = combine_bytes(@data) - 8192 if $name eq 'pitch_bend';
    }
    elsif ($name eq 'sysex')         { $field{msg}      = pack 'C*', grep { $_ != 0xf7 } @data }
    elsif ($name eq 'song_position') { $field{position} = combine_bytes(@data) }
    elsif ($name eq 'song_select')   { $field{song}     = $data[0] }
    elsif ($name eq 'timecode')      { $field{byte}     = $data[0] }
    return bless { name => $name, status => $status, message => [@$message], dt => $dt, %field }, $class;
}

sub name    ($self) { return $self->{name} }
sub status  ($self) { return $self->{status} }
sub message ($self) { return $self->{message} }
sub dt      ($self) { return $self->{dt} }
sub bytes   ($self) { return pack 'C*', @{ $self->{message} } }

# The fields by name: channel, note, velocity, pressure, control, value,
# program, msg, byte, position, song (undef where an event has none).
for my $field (qw(channel note velocity pressure control value program msg byte position song)) {
    no strict 'refs';
    *$field = sub ($self) { return $self->{$field} };
}

sub as_arrayref ($self) { return [ $self->{name}, @$self{ @{ keys_for($self->{name}) } } ] }
sub as_hashref ($self)  { return { name => $self->{name}, map { $_ => $self->{$_} } @{ keys_for($self->{name}) } } }
sub TO_JSON ($self)     { return $self->as_hashref }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Event - a MIDI message as an event: its name and fields

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $event = Peta::MIDI::Event->new([ 0x91, 60, 100 ], 0.25);
    $event->name;           # note_on
    $event->channel;        # 1
    $event->as_arrayref;    # [ 'note_on', 1, 60, 100 ]
    $event->bytes;          # "\x91\x3c\x64"

=head1 DESCRIPTION

The events of L<Peta::MIDI::Decoder> and L<Peta::MIDI::Encoder>, as
MIDI::Stream names them (MIDI::Event's names in brackets), with their
fields in order:

    note_off, note_on   channel note velocity    (a note on of velocity 0 is a note off)
    polytouch           channel note pressure    (key_after_touch)
    control_change      channel control value
    program_change      channel program          (patch_change)
    aftertouch          channel pressure         (channel_after_touch)
    pitch_bend          channel value            (pitch_wheel_change; -8192 .. 8191)
    sysex               msg                      (sysex_f0; the bytes between F0 and F7)
    timecode            byte
    song_position       position                 (0 .. 16383)
    song_select         song
    tune_request, eox (sysex_f7), clock, start, continue, stop,
    active_sensing, system_reset (no fields)

=head1 METHODS

=head2 new

C<new(\@message, $dt)>: the event of a whole message (its bytes as
numbers), C<$dt> the seconds since the one before.

=head2 name, status, message, dt, bytes

The event's name, its status byte, its bytes as numbers, the seconds
since the message before, and its bytes as a string (a system exclusive
message's whole, F0 to F7).

=head2 channel, note, velocity, pressure, control, value, program, msg, byte, position, song

The fields; undef where the event has none.

=head2 as_arrayref, as_hashref, TO_JSON

C<[ name, fields in order ]>; C<{ name, field => value }> (also as JSON).

=head1 FUNCTIONS

=head2 status_byte, status_name

C<status_byte($name)>: a name's status byte (channel 0);
C<status_name($status)>: a status byte's name.

=head2 keys_for

C<keys_for($name)>: the fields of events of a name, in order.

=head2 message_length

C<message_length($status)>: the length of a message with its status
byte; 0 where it is as long as it is (system exclusive).

=head2 split_bytes, combine_bytes

C<split_bytes($value)>: a value of 14 bits as (lsb, msb);
C<combine_bytes($lsb, $msb)> back.

=head2 name_to_midi_event, name_from_midi_event

MIDI::Event's names (C<patch_change>, C<pitch_wheel_change>,
C<key_after_touch>, C<channel_after_touch>, C<sysex_f0>, C<sysex_f7>) and
back; other names as they are.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

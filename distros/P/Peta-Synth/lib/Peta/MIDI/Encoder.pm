package Peta::MIDI::Encoder;
# ABSTRACT: events into MIDI bytes

# Events into MIDI bytes: an event is [ name, fields ... ] (as
# Peta::MIDI::Event has them, MIDI::Event's names too), { name => ...,
# field => ... }, or a Peta::MIDI::Event. A channel message given more
# values than one message holds is several: control_change(0, 7, 100, 10,
# 64) is two. Pitch bends are -8192 .. 8191; a system exclusive message's
# msg is its bytes (a string, or a list of numbers), F0 and F7 added.
#
# enable_running_status leaves out a channel message's status byte when it
# is the last one sent (and sends it again every running_status_retransmit
# messages; real-time messages leave running status as it is, others end
# it); a note off of velocity 0 is then sent as a note on, which keeps it.
# enable_14bit_cc sends controllers 0 .. 31 as values of 14 bits: the
# coarse part when it changes, the fine part (the controller plus 32)
# always.

use v5.36;
use Carp qw(carp);
use Peta::MIDI::Event qw(status_byte keys_for message_length split_bytes);

our $VERSION = '0.2610180';

sub new ($class, %arg) {
    return bless {
        enable_14bit_cc           => $arg{enable_14bit_cc} // 0,
        enable_running_status     => $arg{enable_running_status} // 0,
        running_status_retransmit => $arg{running_status_retransmit} // 10,
        concat                    => $arg{concat} // 0,
        running                   => 0,     # the status last sent, for running status
        repeats                   => 0,     # how many times it has run on
        coarse                    => [],    # controllers' coarse parts last sent, by channel
    }, $class;
}

# An event's bytes: a message each (one string, with concat).
sub encode ($self, $event) {
    my @event  = _fields($event);
    my $name   = Peta::MIDI::Event::name_from_midi_event(shift @event);
    my $status = status_byte($name);
    if (!defined $status) {
        carp "an unknown MIDI event: $name";
        return;
    }

    my @messages;
    if ($name eq 'sysex') {
        my $msg = ref $event[0] eq 'ARRAY' ? pack('C*', @{ $event[0] }) : $event[0] // '';
        $msg =~ s/\A\xf0//;
        $msg .= "\xf7" if $msg !~ /\xf7\z/;
        $self->{running} = 0;
        @messages = ("\xf0$msg");
    }
    elsif ($status < 0xf0) {
        my $channel = shift(@event) & 0x0f;
        my $data    = message_length($status) - 1;
        @event = map { split_bytes($_ + 8192) } @event if $name eq 'pitch_bend';
        while (@event) {
            my @values = splice @event, 0, $data;
            push @messages, $self->_channel_message($status, $channel, @values);
        }
    }
    else {
        @event = split_bytes($event[0]) if $name eq 'song_position';
        $self->{running} = 0 if $status < 0xf8;    # real time leaves running status as it is
        @messages = (pack 'C*', $status, @event[ 0 .. message_length($status) - 2 ]);
    }
    return $self->{concat} ? join('', @messages) : @messages;
}

# An event's name and fields, however it is given.
sub _fields ($event) {
    return @{ $event->as_arrayref } if eval { $event->isa('Peta::MIDI::Event') };
    return @$event if ref $event eq 'ARRAY';
    my $keys = keys_for(Peta::MIDI::Event::name_from_midi_event($event->{name}));
    return ($event->{name}, @$event{@$keys});
}

# A channel message (two, for a controller of 14 bits).
sub _channel_message ($self, $status, $channel, @values) {
    if ($self->{enable_14bit_cc} && $status == 0xb0 && $values[0] < 0x20) {
        my ($number, $value) = @values;
        my ($fine, $coarse) = split_bytes($value);
        my $sent = $self->{coarse}[$channel] //= [];
        my @parts = ([ $number | 0x20, $fine ]);
        unshift @parts, [ $number, $coarse ] if ($sent->[$number] // -1) != $coarse;
        $sent->[$number] = $coarse;
        return map { $self->_bytes($status | $channel, @$_) } @parts;
    }
    $status = 0x90 if $self->{enable_running_status} && $status == 0x80 && !$values[1] && ($self->{running} & 0xf0) != 0x80;
    return $self->_bytes($status | $channel, @values);
}

sub _bytes ($self, $status, @data) {
    if ($self->{enable_running_status}) {
        if ($status == $self->{running} && $self->{repeats}++ < $self->{running_status_retransmit}) {
            return pack 'C*', @data;
        }
        @$self{qw(running repeats)} = ($status, 0);
    }
    return pack 'C*', $status, @data;
}

# Several events' bytes.
sub encode_events ($self, @events) {
    my @bytes = map { $self->encode($_) } @events;
    return $self->{concat} ? join('', @bytes) : @bytes;
}

sub clear_running_status ($self) {
    @$self{qw(running repeats)} = (0, 0);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Encoder - events into MIDI bytes

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $encoder = Peta::MIDI::Encoder->new(enable_running_status => 1);
    my @messages = $encoder->encode([ note_on => 0, 60, 100 ]);
    my $bytes = join '', $encoder->encode_events([ control_change => 0, 7, 100, 10, 64 ], [ pitch_bend => 0, -2048 ]);

=head1 DESCRIPTION

As MIDI::Stream::Encoder does; the events are described at the top of
the source.

=head1 METHODS

=head2 new

C<< new(enable_14bit_cc => 0, enable_running_status => 0, running_status_retransmit => 10, concat => 0) >>.

=head2 encode, encode_events

C<encode($event)>: the event's messages as byte strings (one string with
C<concat>); C<encode_events(@events)> the same of several.

=head2 clear_running_status

The next channel message sends its status byte.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

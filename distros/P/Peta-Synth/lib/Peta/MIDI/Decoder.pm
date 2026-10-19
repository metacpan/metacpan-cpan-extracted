package Peta::MIDI::Decoder;
# ABSTRACT: MIDI bytes into events

# MIDI bytes, as a device or a port sends them, into events
# (Peta::MIDI::Event): running status; system exclusive from F0 to F7 (or
# to the next status byte); real-time bytes (clock, start, active sensing,
# ...) wherever they come, even inside another message. Bytes may come in
# any pieces. The events are kept (retain_events) and handed to callbacks,
# by name; the clock's ticks give the tempo.
#
# With enable_14bit_cc, controllers 0 .. 31 and their fine parts 32 .. 63
# are one: the coarse part alone is kept back, the fine part gives one
# control_change of the coarse number and a value of 14 bits.

use v5.36;
use Time::HiRes qw(time);
use Peta::MIDI::Event qw(message_length combine_bytes keys_for);

our $VERSION = '0.2610180';

use constant { STOP => 'stop', CONTINUE => 'continue' };

my @NAMES = qw(note_off note_on polytouch control_change program_change aftertouch pitch_bend sysex timecode
    song_position song_select tune_request eox clock start continue stop active_sensing system_reset);

sub new ($class, %arg) {
    return bless {
        retain_events   => $arg{retain_events} // 1,
        enable_14bit_cc => $arg{enable_14bit_cc} // 0,
        callback        => $arg{callback},
        clock_ppqn      => $arg{clock_ppqn} // 24,
        clock_samples   => $arg{clock_samples} // 24,
        round_tempo     => $arg{round_tempo} // 0,
        events          => [],
        pending         => [],       # the message so far: status, data
        length          => 0,        # how long it is whole (0: system exclusive)
        coarse          => [],       # controllers' coarse parts, with enable_14bit_cc
        filters         => {},       # name => [ callbacks ]
        last            => undef,    # when the last event was
        ticks           => [],       # the clock's last intervals
        tick            => undef,
    }, $class;
}

sub stop ($self)     { return STOP }
sub continue ($self) { return CONTINUE }

# Bytes in; how many events are kept.
sub decode ($self, @strings) {
    for my $byte (unpack 'C*', join '', @strings) {
        if ($byte >= 0xf8) {
            # Real time: wherever it comes, it is a message of its own.
            $self->_sample_clock if $byte == 0xf8;
            $self->_push([$byte]) if $byte != 0xf9 && $byte != 0xfd;
            next;
        }
        my $pending = $self->{pending};
        if ($byte == 0xf7) {
            # The end of a system exclusive message.
            $self->_push([ @$pending, 0xf7 ]) if @$pending && $pending->[0] == 0xf0;
            $self->_start;
            next;
        }
        if ($byte >= 0x80) {
            # Any other status ends a system exclusive message.
            $self->_push([ @$pending, 0xf7 ]) if @$pending && $pending->[0] == 0xf0;
            if ($byte == 0xf4 || $byte == 0xf5) {    # undefined: no running status after them
                $self->_start;
                next;
            }
            if (message_length($byte) == 1) {
                $self->_push([$byte]);
                $self->_start;
                next;
            }
            $self->_start($byte);
            next;
        }
        next if !@$pending;    # a data byte without a status
        push @$pending, $byte;
        if ($self->{length} && @$pending >= $self->{length}) {
            $self->_push([@$pending]);
            $self->_start($pending->[0] < 0xf0 ? $pending->[0] : undef);    # running status, for channel messages
        }
    }
    return scalar @{ $self->{events} };
}

sub _start ($self, $status = undef) {
    $self->{pending} = defined $status ? [$status] : [];
    $self->{length}  = defined $status ? message_length($status) : 0;
    return;
}

sub _push ($self, $message) {
    $message = $self->_fourteen($message) if $self->{enable_14bit_cc} && ($message->[0] & 0xf0) == 0xb0;
    return if !$message;

    my $now   = time;
    my $dt    = defined $self->{last} ? $now - $self->{last} : 0;
    my $event = Peta::MIDI::Event->new($message, $dt);
    $self->{last} = $now;
    push @{ $self->{events} }, $event if $self->{retain_events};

    for my $callback (@{ $self->{filters}{all} // [] }, @{ $self->{filters}{ $event->name } // [] }) {
        my $said = $callback->($event);
        last if defined $said && $said eq STOP;
    }
    $self->{callback}->($event) if $self->{callback};
    return;
}

# A controller of 14 bits: the coarse part kept, the fine part given with it.
sub _fourteen ($self, $message) {
    my ($status, $number, $value) = @$message;
    return $message if $number > 0x3f;
    my $channel = $status & 0x0f;
    if ($number & 0x20) {
        my $coarse = $self->{coarse}[$channel][ $number & 0x1f ] // return;
        return [ $status, $number & 0x1f, combine_bytes($value, $coarse) ];
    }
    $self->{coarse}[$channel][$number] = $value;
    return;
}

sub _sample_clock ($self) {
    my $now = time;
    if (defined $self->{tick}) {
        push @{ $self->{ticks} }, $now - $self->{tick};
        shift @{ $self->{ticks} } while @{ $self->{ticks} } > $self->{clock_samples};
    }
    $self->{tick} = $now;
    return;
}

# The tempo (beats a minute) the clock's ticks give; undef before two.
sub tempo ($self) {
    my @ticks = @{ $self->{ticks} } or return undef;
    my $mean = 0;
    $mean += $_ / @ticks for @ticks;
    return undef if !$mean;
    my $tempo = 60 / ($mean * $self->{clock_ppqn});
    return $self->{round_tempo} ? 0 + sprintf('%.0f', $tempo) : $tempo;
}

# Callbacks by event name, a pattern of names, a list of them, or 'all';
# a callback's returning $decoder->stop ends the others for that event.
sub attach_callback ($self, $which, $callback) {
    push @{ $self->{filters}{$_} }, $callback for $self->_names($which);
    return;
}

sub cancel_event_callback ($self, $which) {
    delete $self->{filters}{$_} for $self->_names($which);
    return;
}

sub _names ($self, $which) {
    return map { $self->_names($_) } @$which if ref $which eq 'ARRAY';
    return grep { $_ =~ $which } @NAMES if ref $which eq 'Regexp';
    return $which;
}

sub cancel_callback ($self) {
    $self->{callback} = undef;
    return;
}

# The events kept, taken; or the first.
sub events ($self)          { return splice @{ $self->{events} } }
sub fetch_one_event ($self) { return shift @{ $self->{events} } }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Decoder - MIDI bytes into events

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $decoder = Peta::MIDI::Decoder->new(enable_14bit_cc => 1);
    $decoder->attach_callback(qr/^note/ => sub ($event) { say "@{ $event->as_arrayref }" });
    $decoder->decode($bytes);
    my @events = $decoder->events;
    say $decoder->tempo;

=head1 DESCRIPTION

As MIDI::Stream::Decoder does: bytes in any pieces, running status,
system exclusive, real-time bytes anywhere; L<Peta::MIDI::Event>s, kept
and handed to callbacks.

=head1 METHODS

=head2 new

C<< new(retain_events => 1, enable_14bit_cc => 0, callback => sub ($event) {...}, clock_ppqn => 24, clock_samples => 24, round_tempo => 0) >>.

=head2 decode

C<decode(@bytes)>: the bytes decoded; how many events are kept.

=head2 events, fetch_one_event

The events kept, all (and forgotten) or the first.

=head2 attach_callback, cancel_event_callback, cancel_callback, stop, continue

C<attach_callback($which, sub ($event) {...})>: a callback for events of a
name, of names matching a pattern, of a list of names, or C<all>. A
callback that returns C<< $decoder->stop >> ends the others for that event.

=head2 tempo

The beats a minute of the clock's last ticks (C<clock_samples> of them,
C<clock_ppqn> a beat).

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

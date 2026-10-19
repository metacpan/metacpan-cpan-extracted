package Peta::MIDI::Device::In;
# ABSTRACT: a MIDI input as MIDI::RtMidi::FFI::Device::In has it

# A MIDI input as MIDI::RtMidi::FFI::Device::In has it: messages come in
# whole (system exclusive too), each with the seconds since the one before;
# system exclusive, timing (clock, MIDI time code) and active sensing are
# ignored unless told otherwise. They are queued (get_message), handed to a
# callback, or written to a handle (get_fh) as they come.
#
# RtMidi calls the callback from a thread of its own. Here a callback runs
# whenever the program's event loop does (AnyEvent's, and through it EV,
# Event, IO::Async, Coro: a program that waits in Coro sees its callbacks
# run meanwhile), or while the program waits in dispatch().

use v5.36;
use parent 'Peta::MIDI::Device';
use Carp qw(croak);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Scalar::Util qw(weaken);
use Time::HiRes qw(time);
use Peta::MIDI::Decoder;

our $VERSION = '0.2610180';

sub _direction ($self) { return 'in' }

sub _build ($self, %arg) {
    $self->{ignore}            = [ map { $arg{$_} // 1 } qw(ignore_sysex ignore_timing ignore_sensing) ];
    $self->{remap_event_names} = $arg{remap_event_names} // 1;
    $self->{bufsize}           = $arg{bufsize} // $arg{queue_size_limit} // 4096;
    $self->{decoder}           = Peta::MIDI::Decoder->new(
        enable_14bit_cc => $arg{enable_14bit_cc} // 0,
        retain_events   => $arg{retain_events} // 1,
    );
    $self->{framer} = Peta::MIDI::Decoder->new;    # the bytes as they come into whole messages
    $self->{queue}  = [];
    return;
}

sub bufsize ($self) { return $self->{bufsize} }
sub decoder ($self) { return $self->{decoder} }

# What is ignored: system exclusive, timing (clock, MIDI time code), active sensing.
sub ignore_types ($self, $sysex, $timing, $sensing) {
    $self->{ignore} = [ $sysex, $timing, $sensing ];
    return;
}
sub ignore_sysex ($self, $on)   { return $self->ignore_types($on, @{ $self->{ignore} }[ 1, 2 ]) }
sub ignore_timing ($self, $on)  { return $self->ignore_types($self->{ignore}[0], $on, $self->{ignore}[2]) }
sub ignore_sensing ($self, $on) { return $self->ignore_types(@{ $self->{ignore} }[ 0, 1 ], $on) }

# $callback->($dt, $message) for each message as it comes.
sub set_callback ($self, $callback) {
    $self->cancel_callback;
    $self->{callback} = $callback;
    $self->_watch;
    return;
}

# $callback->($dt, $message, $event): the event decoded ([ name, fields ... ]).
sub set_callback_decoded ($self, $callback) {
    return $self->set_callback(sub ($dt, $message) {
        my $event = $self->decode_message($message) // return;
        $callback->($dt, $message, $event);
    });
}

sub cancel_callback ($self) {
    delete @$self{qw(callback watcher fh writer)};
    return;
}

# A non-blocking handle the messages' bytes are written to as they come;
# needs an event loop (AnyEvent) to pump it.
sub get_fh ($self) {
    $self->cancel_callback;
    eval { require AnyEvent; 1 } or croak 'get_fh needs AnyEvent, to pump the handle as messages come';
    pipe(my $reader, my $writer) or croak "a pipe: $!";
    for my $fh ($reader, $writer) {
        binmode $fh;
        fcntl($fh, F_SETFL, fcntl($fh, F_GETFL, 0) | O_NONBLOCK);
    }
    @$self{qw(fh writer)} = ($reader, $writer);
    $self->_watch;
    return $reader;
}

# The sequencer's handle watched in the event loop, if there is AnyEvent.
sub _watch ($self) {
    return if !eval { require AnyEvent; 1 };
    my $weak = $self;
    weaken $weak;
    $self->{watcher} = AnyEvent->io(fh => $self->{alsa}->handle, poll => 'r', cb => sub { $weak->_pump(0) if $weak });
    return;
}

# Waits up to $seconds for messages and hands them out (to the callback,
# the handle or the queue) as they come; how many there were. For a
# program without an event loop.
sub dispatch ($self, $seconds = 0) {
    my $until = time + $seconds;
    my $count = 0;
    while (1) {
        $count += $self->_pump($until - time > 0 ? $until - time : 0);
        last if time >= $until;
    }
    return $count;
}

# What has come, as whole messages, handed out; how many.
sub _pump ($self, $wait) {
    my $framer = $self->{framer};
    for my $message ($self->{alsa}->read($wait)) {
        my ($bytes, undef, $port) = @$message;
        $framer->decode($bytes) if defined $self->{port} && $port == $self->{port};
    }
    my $count = 0;
    for my $event ($framer->events) {
        my $status = $event->status;
        next if $status == 0xf0 && $self->{ignore}[0];
        next if ($status == 0xf8 || $status == 0xf1) && $self->{ignore}[1];
        next if $status == 0xfe && $self->{ignore}[2];

        my $now = time;
        my $dt  = defined $self->{last} ? $now - $self->{last} : 0;
        $self->{last} = $now;
        $count++;
        if    ($self->{callback}) { $self->{callback}->($dt, $event->bytes) }
        elsif ($self->{writer})   { syswrite $self->{writer}, $event->bytes }
        else {
            push @{ $self->{queue} }, $event->bytes;
            shift @{ $self->{queue} } while @{ $self->{queue} } > $self->{bufsize};
        }
    }
    return $count;
}

# The next message (its bytes), or undef.
sub get_message ($self) {
    $self->_pump(0) if !@{ $self->{queue} };
    return shift @{ $self->{queue} };
}

sub get_message_decoded ($self) {
    my $message = $self->get_message // return undef;
    return $self->decode_message($message);
}
sub get_event ($self) { return $self->get_message_decoded }

# A message's event, [ name, fields ... ], MIDI::Event's names unless told
# otherwise (remap_event_names); undef where the message is not whole (or
# is a coarse controller part kept back, with enable_14bit_cc).
sub decode_message ($self, $message) {
    my $decoder = $self->{decoder};
    return undef if !$decoder->decode($message);
    my $event = $decoder->fetch_one_event->as_arrayref;
    $event->[0] = $self->name_to_midi_event($event->[0]) if $self->{remap_event_names};
    return $event;
}
sub decode ($self, $message) { return $self->decode_message($message) }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Device::In - a MIDI input as MIDI::RtMidi::FFI::Device::In has it

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $in = Peta::MIDI::Device::In->new(name => 'listener', ignore_timing => 0);
    $in->open_port_by_name(qr/keyboard/i);

    # Callbacks: in an event loop, or while waiting in dispatch.
    $in->set_callback_decoded(sub ($dt, $msg, $event) { say "@$event" });
    AnyEvent->condvar->recv;           # or EV::run, or Coro waiting; or $in->dispatch(60)

    # A handle for an event loop of one's own.
    my $fh = $in->get_fh;

    # Or the queue.
    while (my $event = $in->get_event) { ... }

=head1 DESCRIPTION

Messages come in whole, each with the seconds since the one before.
System exclusive, timing (clock, MIDI time code) and active sensing are
ignored unless C<ignore_sysex>, C<ignore_timing>, C<ignore_sensing> are
given false. Decoded, events are C<[ name, fields ... ]> as
L<Peta::MIDI::Event> lists them, in MIDI::Event's names unless
C<remap_event_names> is false.

RtMidi calls a callback from a thread of its own; here it runs whenever
the program's event loop runs (L<AnyEvent>'s, and through it EV, Event,
IO::Async or Coro), or while the program waits in C<dispatch>.

=head1 METHODS

=head2 new

C<< new(name => ..., ignore_sysex => 1, ignore_timing => 1, ignore_sensing => 1, enable_14bit_cc => 0, retain_events => 1, bufsize => 4096, remap_event_names => 1) >>
(C<queue_size_limit> is C<bufsize>: the messages the queue holds).

=head2 set_callback, set_callback_decoded, cancel_callback

C<set_callback(sub ($dt, $message) {...})>,
C<set_callback_decoded(sub ($dt, $message, $event) {...})>.

=head2 get_fh

A non-blocking handle the messages' bytes are written to as they come
(pumped by the event loop; needs AnyEvent).

=head2 dispatch

C<dispatch($seconds)>: waits, handing the messages out as they come; how
many there were. Not RtMidi's: for a program without an event loop.

=head2 get_message, get_message_decoded, get_event, decode_message, decode, decoder

The next message's bytes, or its event; an event of a message's bytes;
the decoder (L<Peta::MIDI::Decoder>).

=head2 ignore_types, ignore_sysex, ignore_timing, ignore_sensing, bufsize

C<ignore_types($sysex, $timing, $sensing)>, or each alone.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

package Peta::Synth::Output::PipeWire;
# ABSTRACT: sound to PipeWire as it plays (pperl)

# Sound to PipeWire as it plays, through PipeWire's own library
# (libpipewire-0.3, MIT licensed), called with pperl's Peta::FFI: pperl
# only. perl5 plays through Peta::Synth::Output::Pulse.
#
# libpipewire runs its loop in a thread of its own (pw_thread_loop), and C
# never calls back into Perl: write() takes the loop's lock, takes the
# empty buffers the stream has (pw_stream_dequeue_buffer), fills them,
# gives them back (pw_stream_queue_buffer), and lets go of the lock; while
# more is waiting than the stream takes, it sleeps a few milliseconds and
# looks again. The stream's pace is the caller's.
#
# What crosses the boundary is laid out here by hand, as the headers of
# PipeWire 1.x have it on a 64-bit machine:
#
#   pw_stream_events   uint32 version, then 11 function pointers (all NULL)
#   pw_buffer          spa_buffer *buffer @0, user_data @8, uint64 size @16,
#                      uint64 requested @24
#   spa_buffer         uint32 n_metas, n_datas, spa_meta *metas @8, spa_data *datas @16
#   spa_data           uint32 type, flags, int64 fd @8, uint32 mapoffset @16,
#                      uint32 maxsize @20, void *data @24, spa_chunk *chunk @32
#   spa_chunk          uint32 offset, uint32 size, int32 stride, int32 flags
#   pw_time            ... uint64 queued @32 ...  (64 bytes)
#
# The stream's format is an SPA POD built here: an Object of type Format,
# id EnumFormat, with media type audio, subtype raw, format F32LE, the rate,
# two channels, positions FL FR.

use v5.36;
use Time::HiRes ();
use Peta::Synth::Output;

our $VERSION = '0.2610180';

use constant {
    LIBRARY          => 'libpipewire-0.3.so.0',
    DIRECTION_OUTPUT => 1,
    ID_ANY           => -1,       # 0xFFFFFFFF, as the C int it is passed as
    AUTOCONNECT      => 1,
    MAP_BUFFERS      => 4,
    STATE_ERROR      => -1,
    STATE_PAUSED     => 2,
    STATE_STREAMING  => 3,
    FRAME            => 8,        # bytes: two 32-bit floats
    POLL             => 0.002,    # seconds between looks at the stream
};

# SPA types and keys (spa/utils/type.h, spa/param/*.h).
use constant {
    TYPE_ID               => 3,
    TYPE_INT              => 4,
    TYPE_ARRAY            => 13,
    TYPE_OBJECT           => 15,
    OBJECT_FORMAT         => 0x40003,
    PARAM_ENUMFORMAT      => 3,
    FORMAT_MEDIATYPE      => 1,
    FORMAT_MEDIASUBTYPE   => 2,
    FORMAT_AUDIO_FORMAT   => 0x10001,
    FORMAT_AUDIO_RATE     => 0x10003,
    FORMAT_AUDIO_CHANNELS => 0x10004,
    FORMAT_AUDIO_POSITION => 0x10005,
    MEDIA_AUDIO           => 1,
    SUBTYPE_RAW           => 1,
    AUDIO_F32LE           => 0x11B,
    CHANNEL_FL            => 3,
    CHANNEL_FR            => 4,
};

my ($LIB, $INIT);

sub _call ($name, $signature, @args) { return Peta::FFI::call($LIB, $name, $signature, @args) }

# Whether PipeWire can be played to from here: pperl's Peta::FFI and the
# library. Leaves the reason in $@ when not.
sub available () {
    return 1 if $LIB;
    return 0 if !eval { require Peta::FFI; 1 };
    $LIB = eval { Peta::FFI::dlopen(LIBRARY) };
    return 1 if $LIB;

    $@ ||= 'no ' . LIBRARY . "\n";
    return 0;
}

# new(rate => 48000, latency => 0.1, title => ...): a stream, connected and
# ready; dies with the reason when PipeWire will not have it.
sub new ($class, %opt) {
    available() or die "PipeWire cannot be played to from here: $@";
    if (!$INIT) {
        _call('pw_init', '(oo)v', 0, 0);
        $INIT = 1;
    }

    my $rate    = $opt{rate} // 48000;
    my $latency = int(($opt{latency} // 0.1) * $rate);    # in frames
    my $self    = bless {
        rate    => $rate,
        latency => $latency,
        fifo    => '',                  # sound not yet in the stream's buffers
        want    => $latency * FRAME,    # bytes a buffer takes
        written => 0,
        mem     => [],                  # memory given to C, freed with the stream
    }, $class;

    $self->{loop} = _call('pw_thread_loop_new', '(po)o', 'peta-synth', 0) or die "PipeWire: no thread loop\n";
    my $title = ($opt{title} // 'Peta::Synth') =~ tr/"\\//dr;
    my $props = _call('pw_properties_new_string', '(p)o',
        qq{media.type=Audio media.category=Playback media.role=Music node.latency=$latency/$rate }
        . qq{application.name="Peta::Synth" media.name="$title" node.name="peta-synth"});
    my $events = $self->_alloc(pack 'L< x92', 2);    # version 2, no callbacks
    _call('pw_thread_loop_lock', '(o)v', $self->{loop});
    _call('pw_thread_loop_start', '(o)i', $self->{loop});
    $self->{stream} = _call('pw_stream_new_simple', '(opooo)o',
        _call('pw_thread_loop_get_loop', '(o)o', $self->{loop}), 'Peta::Synth', $props, $events, 0);
    my $format = $self->_alloc(_format($rate));
    my $params = $self->_alloc(Peta::FFI::pack_ptr($format));
    my $connected = $self->{stream}
        && _call('pw_stream_connect', '(oiiioi)i', $self->{stream}, DIRECTION_OUTPUT, ID_ANY, AUTOCONNECT | MAP_BUFFERS, $params, 1);
    _call('pw_thread_loop_unlock', '(o)v', $self->{loop});
    if (!$self->{stream} || $connected < 0) {
        $self->_destroy;
        die "PipeWire refused the stream\n";
    }

    # Until it is ready to take sound, or says why not.
    my $until = Time::HiRes::time() + 5;
    while (1) {
        my ($state, $error) = $self->_state;
        last if $state == STATE_STREAMING || $state == STATE_PAUSED;
        if ($state == STATE_ERROR || Time::HiRes::time() > $until) {
            $self->_destroy;
            die 'PipeWire: ' . ($error // 'the stream did not get ready') . "\n";
        }
        Time::HiRes::sleep(0.01);
    }
    return $self;
}

sub rate ($self) { return $self->{rate} }

# Seconds of sound handed to the stream.
sub sent ($self) { return $self->{written} / FRAME / $self->{rate} }

# Sound: queued as the stream takes it; waits while more is waiting than
# it takes.
sub write ($self, $left, $right) {
    $self->{fifo} .= pack 'f<*', @{ Peta::Synth::Output::interleave($left, $right) };
    $self->_pump(0);
    while (length $self->{fifo} > $self->{want}) {
        Time::HiRes::sleep(POLL);
        $self->_pump(0);
    }
    return $self;
}

# The rest played to its end, then the stream let go.
sub close ($self) {
    return if !$self->{stream};
    while (length $self->{fifo}) {
        $self->_pump(1);
        Time::HiRes::sleep(POLL) if length $self->{fifo};
    }
    my $time = $self->{time} //= $self->_alloc("\0" x 64);
    my $until = Time::HiRes::time() + 10;
    while (Time::HiRes::time() < $until) {
        _call('pw_thread_loop_lock', '(o)v', $self->{loop});
        _call('pw_stream_get_time_n', '(ooL)i', $self->{stream}, $time, 64);
        _call('pw_thread_loop_unlock', '(o)v', $self->{loop});
        my ($delay, $queued) = unpack 'q< Q<', Peta::FFI::peek($time + 24, 16);
        if (!$queued) {
            # All is queued out; what is in the device still plays, $delay frames.
            Time::HiRes::sleep($delay > 0 && $delay < $self->{rate} ? $delay / $self->{rate} : 0.05);
            last;
        }
        Time::HiRes::sleep(0.01);
    }
    $self->_destroy;
    return;
}

# Stops at once.
sub stop ($self) { $self->_destroy; return }

sub DESTROY ($self) { $self->_destroy if $self->{loop} && ${^GLOBAL_PHASE} ne 'DESTRUCT' }

# Fills the empty buffers the stream has, as far as the sound waiting goes
# (all of it, short buffers too, when $final), and while the stream holds
# less than twice the latency: a buffer takes what PipeWire asks for, or
# the latency's worth.
sub _pump ($self, $final) {
    my $time = $self->{time} //= $self->_alloc("\0" x 64);
    _call('pw_thread_loop_lock', '(o)v', $self->{loop});
    while (length($self->{fifo}) >= ($final ? 1 : $self->{want})) {
        _call('pw_stream_get_time_n', '(ooL)i', $self->{stream}, $time, 64);
        my ($queued) = unpack 'Q<', Peta::FFI::peek($time + 32, 8);
        last if $queued >= 2 * $self->{latency};
        my $b = _call('pw_stream_dequeue_buffer', '(o)o', $self->{stream}) or last;
        my $buffer = Peta::FFI::unpack_ptr(Peta::FFI::peek($b, 8));
        my $datas  = Peta::FFI::unpack_ptr(Peta::FFI::peek($buffer + 16, 8));
        my ($maxsize) = unpack 'L<', Peta::FFI::peek($datas + 20, 4);
        my $data  = Peta::FFI::unpack_ptr(Peta::FFI::peek($datas + 24, 8));
        my $chunk = Peta::FFI::unpack_ptr(Peta::FFI::peek($datas + 32, 8));
        my ($requested) = unpack 'Q<', Peta::FFI::peek($b + 24, 8);
        my $bytes = ($requested || $self->{latency}) * FRAME;
        $bytes = $maxsize - $maxsize % FRAME if $bytes > $maxsize;
        $self->{want} = $bytes if $bytes > 0;
        my $part = substr $self->{fifo}, 0, $bytes, '';
        Peta::FFI::poke($data, $part) if length $part;
        Peta::FFI::poke($chunk, pack 'L< L< l< l<', 0, length $part, FRAME, 0);
        Peta::FFI::poke($b + 16, pack 'Q<', length($part) / FRAME);
        _call('pw_stream_queue_buffer', '(oo)i', $self->{stream}, $b);
        $self->{written} += length $part;
    }
    _call('pw_thread_loop_unlock', '(o)v', $self->{loop});
    return;
}

sub _state ($self) {
    my $out = $self->_alloc("\0" x 8);
    _call('pw_thread_loop_lock', '(o)v', $self->{loop});
    my $state = _call('pw_stream_get_state', '(oo)i', $self->{stream}, $out);
    _call('pw_thread_loop_unlock', '(o)v', $self->{loop});
    my $error = Peta::FFI::unpack_ptr(Peta::FFI::peek($out, 8));
    return ($state, $error ? Peta::FFI::peek_cstr($error) : undef);
}

# Memory for C, freed with the stream.
sub _alloc ($self, $bytes) {
    my $p = Peta::FFI::alloc(length $bytes);
    Peta::FFI::poke($p, $bytes);
    push @{ $self->{mem} }, $p;
    return $p;
}

sub _destroy ($self) {
    return if !$self->{loop};
    if ($self->{stream}) {
        _call('pw_thread_loop_lock', '(o)v', $self->{loop});
        _call('pw_stream_disconnect', '(o)i', $self->{stream});
        _call('pw_stream_destroy', '(o)v', $self->{stream});
        _call('pw_thread_loop_unlock', '(o)v', $self->{loop});
        delete $self->{stream};
    }
    _call('pw_thread_loop_stop', '(o)v', $self->{loop});
    _call('pw_thread_loop_destroy', '(o)v', $self->{loop});
    delete $self->{loop};
    Peta::FFI::free($_) for @{ $self->{mem} };
    $self->{mem} = [];
    return;
}

# An SPA POD: size, type, the body padded to a multiple of 8 bytes,
# little-endian.
sub _pod ($type, $body) {
    my $pad = (8 - length($body) % 8) % 8;
    return pack('L< L<', length $body, $type) . $body . ("\0" x $pad);
}

# A property of an object POD: its key, no flags, its value.
sub _prop ($key, $pod) { return pack('L< L<', $key, 0) . $pod }

# The stream's format: an Object of type Format, id EnumFormat.

sub _format ($rate) {
    my $id  = sub ($v) { _pod(TYPE_ID, pack 'L<', $v) };
    my $int = sub ($v) { _pod(TYPE_INT, pack 'l<', $v) };
    my $positions = _pod(TYPE_ARRAY, pack('L< L<', 4, TYPE_ID) . pack('L< L<', CHANNEL_FL, CHANNEL_FR));
    return _pod(TYPE_OBJECT, pack('L< L<', OBJECT_FORMAT, PARAM_ENUMFORMAT)
        . _prop(FORMAT_MEDIATYPE, $id->(MEDIA_AUDIO))
        . _prop(FORMAT_MEDIASUBTYPE, $id->(SUBTYPE_RAW))
        . _prop(FORMAT_AUDIO_FORMAT, $id->(AUDIO_F32LE))
        . _prop(FORMAT_AUDIO_RATE, $int->($rate))
        . _prop(FORMAT_AUDIO_CHANNELS, $int->(2))
        . _prop(FORMAT_AUDIO_POSITION, $positions));
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Output::PipeWire - sound to PipeWire as it plays (pperl)

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    if (Peta::Synth::Output::PipeWire::available()) {
        my $out = Peta::Synth::Output::PipeWire->new(rate => 48000, latency => 0.1);
        $out->write(\@left, \@right) while ...;    # waits while the stream has enough
        $out->close;                                # plays the rest to its end
    }

=head1 DESCRIPTION

A PipeWire stream through libpipewire (MIT licensed), called with pperl's
L<Peta::FFI>; perl5 has no such FFI, and plays through
L<Peta::Synth::Output::Pulse>. libpipewire runs its loop in its own
thread; C never calls back into Perl: the writer fills the stream's empty
buffers under the loop's lock, and waits while they are full. The same
methods as L<Peta::Synth::Output::Pulse>.

=head1 METHODS

=head2 new

C<< new(rate => 48000, latency => 0.1, title => ...) >>: a stream of floats
in two channels; C<latency> the seconds PipeWire is asked to keep its
cycle to.

=head2 write, close, stop, sent, rate

As for L<Peta::Synth::Output::Pulse>.

=head1 FUNCTIONS

=head2 available

Whether this perl has Peta::FFI and the library loads; C<$@> says why not.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

package Peta::Synth::Output::Pulse;
# ABSTRACT: sound to the sound server as it plays (PulseAudio or PipeWire)

# Sound to the sound server, as it plays: a client of the PulseAudio native
# protocol, which PipeWire speaks too (pipewire-pulse) and which carries the
# sound on the socket itself. PipeWire's own protocol passes the sound in
# shared memory (memfd), its file descriptors sent over the socket
# (SCM_RIGHTS): Perl's core has no sendmsg for that, and reaches it only
# through syscall(), with each architecture's syscall numbers and struct
# layouts (pperl also through Peta::FFI). This protocol needs none of that.
#
# The protocol: packets of a descriptor (five 32-bit numbers: length,
# channel, offset high and low, flags) and a payload. Commands go on
# channel 0xFFFFFFFF as tagged values (a type byte, then the value);
# sound goes on the channel the server gave the stream. The server says how
# many bytes it wants (in its reply to the stream's creation, then in
# REQUEST commands); write() sends no more than that, and waits for the
# next request when it has sent it all: the server's clock paces whoever
# writes.
#
# Floats, two channels, at the synthesizer's rate; the server converts.

use v5.36;
use IO::Socket::UNIX;
use IO::Select;
use Peta::Synth::Output;

our $VERSION = '0.2610180';

use constant {
    VERSION     => 32,            # of the protocol: what this client sends
    CONTROL     => 0xFFFFFFFF,    # the channel of commands
    INVALID     => 0xFFFFFFFF,
    FRAME       => 8,             # bytes: two 32-bit floats
    FLOAT32LE   => 5,
    FRONT_LEFT  => 1,
    FRONT_RIGHT => 2,
    VOLUME_NORM => 0x10000,
    TIMEOUT     => 10,            # seconds a reply may take
};

# The commands.
use constant {
    ERROR                  => 0,
    REPLY                  => 2,
    CREATE_PLAYBACK_STREAM => 3,
    DELETE_PLAYBACK_STREAM => 4,
    AUTH                   => 8,
    SET_CLIENT_NAME        => 9,
    DRAIN_PLAYBACK_STREAM  => 12,
    REQUEST                => 61,
    PLAYBACK_STREAM_KILLED => 64,
};

# Where the server is: $PULSE_SERVER (unix:/path or a path), or the socket
# in the user's runtime directory.
sub address () {
    my $server = $ENV{PULSE_SERVER};
    if (defined $server && length $server) {
        for my $one (split ' ', $server) {
            return $1 if $one =~ m{\Aunix:(.+)\z};
            return $one if $one =~ m{\A/};
        }
        die "only local servers (unix:/path) are spoken to, not '$server'\n";
    }
    my $runtime = $ENV{XDG_RUNTIME_DIR} // "/run/user/$<";
    return "$runtime/pulse/native";
}

# Whether there is a server to play to.
sub available () { return -S address() }

# new(rate => 48000, latency => 0.1, name => 'Peta::Synth'): connected,
# authenticated, with a stream; dies with the server's word for why not.
sub new ($class, %opt) {
    my $path   = address();
    my $socket = IO::Socket::UNIX->new(Peer => $path) or die "no sound server at $path: $!\n";
    binmode $socket;

    my $self = bless {
        socket    => $socket,
        select    => IO::Select->new($socket),
        tag       => 0,     # the next command's
        buffer    => '',    # what has come and is not yet read
        rate      => $opt{rate} // 48000,
        requested => 0,     # bytes the server has asked for
        written   => 0,     # bytes sent
    }, $class;

    my ($version) = $self->_command(AUTH, _u32(VERSION) . _arbitrary(_cookie()));
    $self->{version} = ($version & 0xFFFF) < VERSION ? $version & 0xFFFF : VERSION;
    die "the sound server speaks protocol $self->{version}; at least 13 is needed\n" if $self->{version} < 13;

    $self->_command(SET_CLIENT_NAME, _proplist('application.name' => $opt{name} // 'Peta::Synth'));

    my $body = _stream_body($self->{version}, $self->{rate}, $opt{latency} // 0.1, $opt{title} // 'Peta::Synth');
    my ($channel, undef, $requested) = $self->_command(CREATE_PLAYBACK_STREAM, $body);
    $self->{channel}   = $channel;
    $self->{requested} = $requested;

    return $self;
}

# What CREATE_PLAYBACK_STREAM asks for, as protocol $version has it: floats,
# front left and right, to the default sink; the server to keep about
# $latency seconds ahead of what it plays.
sub _stream_body ($version, $rate, $latency, $title) {
    my $target = int($latency * $rate) * FRAME;

    my $body = join '',
        _sample_spec(FLOAT32LE, 2, $rate),
        _channel_map(FRONT_LEFT, FRONT_RIGHT),
        _u32(INVALID), _string(undef),               # the default sink
        _u32(INVALID),                               # maxlength: the server's
        _boolean(0),                                 # not corked
        _u32($target),                               # tlength
        _u32(INVALID), _u32(INVALID),                # prebuf, minreq: the server's
        _u32(0),                                     # sync id
        _cvolume(VOLUME_NORM, VOLUME_NORM),
        (map { _boolean(0) } 1 .. 7),                # no remap, no remix, fix format, rate, channels; may move; fixed rate
        _boolean(0),                                 # not muted
        _boolean(1),                                 # adjust the latency
        _proplist('media.name' => $title, 'media.role' => 'music');

    $body .= _boolean(0) . _boolean(0)               if $version >= 14;    # volume not set; no early requests
    $body .= _boolean(0) . _boolean(0) . _boolean(0) if $version >= 15;    # mute not set; may suspend; no failing on suspend
    $body .= _boolean(0)                             if $version >= 17;    # volume not relative
    $body .= _boolean(0)                             if $version >= 18;    # no passthrough
    $body .= _u8(0)                                  if $version >= 21;    # no formats beyond the sample spec

    return $body;
}

sub rate ($self) { return $self->{rate} }

# Seconds of sound sent so far.
sub sent ($self) { return $self->{written} / FRAME / $self->{rate} }

# Sound: as much as the server asks for is sent, and then this waits for
# it to ask again.
sub write ($self, $left, $right) {
    my $bytes = pack 'f<*', @{ Peta::Synth::Output::interleave($left, $right) };
    while (length $bytes) {
        $self->_receive(1) while $self->{requested} < FRAME;

        my $part = substr $bytes, 0, $self->{requested} - $self->{requested} % FRAME, '';
        $self->_send($self->{channel}, $part);
        $self->{requested} -= length $part;
        $self->{written}   += length $part;
        $self->_receive(0);
    }
    return $self;
}

# Whether the server would take more now, without waiting.
sub wants ($self) {
    $self->_receive(0);
    return $self->{requested} >= FRAME;
}

# The rest played to its end, the stream let go, the connection closed.
sub close ($self) {
    return if !$self->{socket};
    eval {
        $self->_command(DRAIN_PLAYBACK_STREAM, _u32($self->{channel}), 60);
        $self->_command(DELETE_PLAYBACK_STREAM, _u32($self->{channel}));
    };
    my $error = $@;
    CORE::close $self->{socket};
    delete $self->{socket};
    die $error if $error;
    return;
}

# Stops at once: what the server still holds is not played.
sub stop ($self) {
    return if !$self->{socket};
    eval { $self->_command(DELETE_PLAYBACK_STREAM, _u32($self->{channel})) };
    CORE::close $self->{socket};
    delete $self->{socket};
    return;
}

sub DESTROY ($self) { $self->stop if $self->{socket} && ${^GLOBAL_PHASE} ne 'DESTRUCT' }

# A command and its reply: the values the reply holds.
sub _command ($self, $command, $body, $timeout = TIMEOUT) {
    my $tag = $self->{tag}++;
    $self->_send(CONTROL, _u32($command) . _u32($tag) . $body);
    my $until = time + $timeout;
    while (time <= $until) {
        my $reply = $self->_receive(1, $tag) // next;
        return @$reply;
    }
    die "the sound server did not answer\n";
}

sub _send ($self, $channel, $payload) {
    my $packet = pack('N5', length $payload, $channel, 0, 0, 0) . $payload;
    while (length $packet) {
        my $sent = syswrite $self->{socket}, $packet;
        die "the sound server went away: $!\n" if !defined $sent;
        substr($packet, 0, $sent) = '';
    }
    return;
}

# Reads what has come (waiting for something if $wait), handles the
# server's commands; returns the reply to $tag when it is among them.
sub _receive ($self, $wait, $tag = undef) {
    my $got;
    if ($self->{select}->can_read($wait ? 1 : 0)) {
        my $read = sysread $self->{socket}, $self->{buffer}, 65536, length $self->{buffer};
        die "the sound server went away\n" if !$read;
    }
    while (length $self->{buffer} >= 20) {
        my ($length, $channel) = unpack 'N2', $self->{buffer};
        last if length $self->{buffer} < 20 + $length;
        my $payload = substr $self->{buffer}, 20, $length;
        substr($self->{buffer}, 0, 20 + $length) = '';
        next if $channel != CONTROL;    # sound for us: none is asked for
        my @values = _values($payload);
        my ($command, $their_tag) = splice @values, 0, 2;
        if ($command == REQUEST) {
            $self->{requested} += $values[1] if $values[0] == $self->{channel};
        }
        elsif ($command == PLAYBACK_STREAM_KILLED) {
            die "the sound server ended the stream\n";
        }
        elsif ($command == ERROR) {
            die "the sound server refused: error $values[0]\n" if defined $tag && $their_tag == $tag;
        }
        elsif ($command == REPLY && defined $tag && $their_tag == $tag) {
            $got = \@values;
        }
    }
    return $got;
}

# The cookie that proves this user may play; a server that does not ask
# for one takes zeros.
sub _cookie () {
    my @dirs  = grep { defined } $ENV{XDG_CONFIG_HOME}, "$ENV{HOME}/.config";
    my @files = ($ENV{PULSE_COOKIE}, map { "$_/pulse/cookie" } @dirs);

    for my $file (@files) {
        next if !defined $file || !-r $file;
        open my $fh, '<:raw', $file or next;
        read $fh, my $cookie, 256;
        return $cookie if length $cookie == 256;
    }
    return "\0" x 256;
}

# Tagged values.
sub _u8 ($v)       { return 'B' . pack 'C', $v }
sub _u32 ($v)      { return 'L' . pack 'N', $v }
sub _boolean ($v)  { return $v ? '1' : '0' }
sub _string ($s)   { return defined $s ? "t$s\0" : 'N' }
sub _arbitrary ($bytes) { return 'x' . pack('N', length $bytes) . $bytes }
sub _sample_spec ($format, $channels, $rate) { return 'a' . pack 'C C N', $format, $channels, $rate }
sub _channel_map (@positions) { return 'm' . pack 'C C*', scalar @positions, @positions }
sub _cvolume (@volumes) { return 'v' . pack 'C N*', scalar @volumes, @volumes }
sub _proplist (%props) {
    my $list = 'P';
    for my $key (sort keys %props) {
        my $value = "$props{$key}\0";
        $list .= _string($key) . _u32(length $value) . _arbitrary($value);
    }
    return $list . _string(undef);
}

# The values of a payload, as far as they are of the kinds read here.
#
# Each type reads its value at $at and says how many bytes it took; lists
# (sample specs, channel maps, volumes, timevals) are array references.
my %VALUE = (
    L => sub ($p, $at) { (unpack('N', substr $p, $at, 4), 4) },
    B => sub ($p, $at) { (unpack('C', substr $p, $at, 1), 1) },
    R => sub ($p, $at) { (unpack('Q>', substr $p, $at, 8), 8) },
    r => sub ($p, $at) { (unpack('Q>', substr $p, $at, 8), 8) },
    U => sub ($p, $at) { (unpack('Q>', substr $p, $at, 8), 8) },
    1 => sub ($p, $at) { ('1', 0) },
    0 => sub ($p, $at) { ('0', 0) },
    N => sub ($p, $at) { (undef, 0) },
    t => sub ($p, $at) {
        my $end = index $p, "\0", $at;
        return (substr($p, $at, $end - $at), $end - $at + 1);
    },
    x => sub ($p, $at) {
        my $n = unpack 'N', substr $p, $at, 4;
        return (substr($p, $at + 4, $n), 4 + $n);
    },
    a => sub ($p, $at) { ([ unpack 'C C N', substr $p, $at, 6 ], 6) },
    m => sub ($p, $at) {
        my $n = unpack 'C', substr $p, $at, 1;
        return ([ unpack "C$n", substr $p, $at + 1, $n ], 1 + $n);
    },
    v => sub ($p, $at) {
        my $n = unpack 'C', substr $p, $at, 1;
        return ([ unpack "N$n", substr $p, $at + 1, 4 * $n ], 1 + 4 * $n);
    },
    T => sub ($p, $at) { ([ unpack 'N2', substr $p, $at, 8 ], 8) },
);

sub _values ($payload) {
    my @values;
    my $at = 0;
    while ($at < length $payload) {
        my $type = substr $payload, $at++, 1;
        my $read = $VALUE{$type} // last;    # proplists and formats: nothing here needs them, and they come last

        my ($value, $bytes) = $read->($payload, $at);
        push @values, $value;
        $at += $bytes;
    }
    return @values;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Output::Pulse - sound to the sound server as it plays (PulseAudio or PipeWire)

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $out = Peta::Synth::Output::Pulse->new(rate => 48000, latency => 0.1);
    $out->write(\@left, \@right) while ...;    # waits when the server has enough
    $out->close;                                # plays the rest to its end

=head1 DESCRIPTION

A client of the PulseAudio native protocol in Perl, core modules only. It
plays through PulseAudio and through PipeWire (whose pipewire-pulse serves
the same protocol, on the same socket). The server is the one
C<$PULSE_SERVER> names (a local socket), or the user's own.

=head1 METHODS

=head2 new

C<< new(rate => 48000, latency => 0.1, name => ..., title => ...) >>:
connected, with a stream of floats in two channels; C<latency> the seconds
the server holds ahead of what it plays.

=head2 write

C<write(\@left, \@right)>: sends the sound as the server asks for it, and
waits while it has enough.

=head2 wants

Whether the server would take more now.

=head2 sent

Seconds of sound sent.

=head2 close, stop

C<close> plays what the server holds to its end; C<stop> drops it.

=head1 FUNCTIONS

=head2 available

Whether there is a server's socket.

=head2 address, rate

The path of the server's socket; the sample rate played.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

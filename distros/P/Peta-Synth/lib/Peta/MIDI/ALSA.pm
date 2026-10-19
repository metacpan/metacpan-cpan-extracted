package Peta::MIDI::ALSA;
# ABSTRACT: a client of the ALSA sequencer, with no library

# A client of the ALSA sequencer, the kernel's MIDI router, spoken to by
# ioctl(), read() and write() on /dev/snd/seq (no library; perl5 and pperl
# alike). Keyboards on USB, MIDI interfaces, synthesizers, software
# keyboards and sequencers are its clients; PipeWire bridges its own MIDI
# to it. This client makes ports of its own (for others to write to, or to
# read from), connects them to other clients' ports, and turns the
# sequencer's events into MIDI bytes and back.
#
# The kernel's structures, as <sound/asequencer.h> has them (64-bit):
#
#   snd_seq_event         28 bytes: type, flags, tag, queue, time (8), source
#                         and dest (client, port), data (12); data of variable
#                         length follows the event, in what read() gives
#                         padded to a whole number of events
#   snd_seq_client_info   188 bytes: client, type, name[64], ...
#   snd_seq_port_info     168 bytes: client, port, name[64], capability,
#                         type, ...
#   snd_seq_port_subscribe  80 bytes: sender, dest, voices, flags, queue, ...

use v5.36;
use Peta::MIDI::Decoder;
use Peta::MIDI::Event qw(split_bytes);

our $VERSION = '0.2610180';

use constant {
    DEVICE            => '/dev/snd/seq',
    EVENT_SIZE        => 28,
    CLIENT_SIZE       => 188,
    PORT_SIZE         => 168,
    SUBS_SIZE         => 80,
    CAP_READ          => 1 << 0,     # a port's capabilities
    CAP_WRITE         => 1 << 1,
    CAP_SUBS_READ     => 1 << 5,
    CAP_SUBS_WRITE    => 1 << 6,
    CAP_NO_EXPORT     => 1 << 7,
    TYPE_MIDI_GENERIC => 1 << 1,     # and its types
    TYPE_APPLICATION  => 1 << 20,
    LENGTH_MASK       => 3 << 2,     # an event's flags: its data's length
    LENGTH_VARIABLE   => 1 << 2,
    QUEUE_DIRECT      => 253,
    SUBSCRIBERS       => 254,        # the client an event to every subscriber goes to
    UNKNOWN           => 253,
};

# The sequencer's event types, and the MIDI status of each.
use constant {
    NOTEON       => 6,
    NOTEOFF      => 7,
    KEYPRESS     => 8,
    CONTROLLER   => 10,
    PGMCHANGE    => 11,
    CHANPRESS    => 12,
    PITCHBEND    => 13,
    CONTROL14    => 14,     # a controller of 14 bits
    NONREGPARAM  => 15,     # an NRPN
    REGPARAM     => 16,     # an RPN
    SONGPOS      => 20,
    SONGSEL      => 21,
    QFRAME       => 22,
    START        => 30,
    CONTINUE     => 31,
    STOP         => 32,
    CLOCK        => 36,
    TUNE_REQUEST => 40,
    RESET        => 41,
    SENSING      => 42,
    PORT_START   => 63,
    PORT_EXIT    => 64,
    SYSEX        => 130,
};
my %STATUS_OF = (
    NOTEOFF, 0x80, NOTEON, 0x90, KEYPRESS, 0xa0, CONTROLLER, 0xb0, PGMCHANGE, 0xc0, CHANPRESS, 0xd0, PITCHBEND, 0xe0,
    QFRAME, 0xf1, SONGPOS, 0xf2, SONGSEL, 0xf3, TUNE_REQUEST, 0xf6, CLOCK, 0xf8, START, 0xfa, CONTINUE, 0xfb,
    STOP, 0xfc, SENSING, 0xfe, RESET, 0xff,
);
my %TYPE_OF = reverse %STATUS_OF;

# The ioctls: direction (1 write, 2 read, 3 both), number, size.
sub _io ($dir, $nr, $size) { return ($dir << 30) | ($size << 16) | (ord('S') << 8) | $nr }
my %IOCTL = (
    client_id       => _io(2, 0x01, 4),
    get_client_info => _io(3, 0x10, CLIENT_SIZE),
    set_client_info => _io(1, 0x11, CLIENT_SIZE),
    create_port     => _io(3, 0x20, PORT_SIZE),
    delete_port     => _io(1, 0x21, PORT_SIZE),
    get_port_info   => _io(3, 0x22, PORT_SIZE),
    subscribe       => _io(1, 0x30, SUBS_SIZE),
    unsubscribe     => _io(1, 0x31, SUBS_SIZE),
    next_client     => _io(3, 0x51, CLIENT_SIZE),
    next_port       => _io(3, 0x52, PORT_SIZE),
);

my $PORT = 'C C Z64 x2 I I i i i i i Q I C C C a57';    # snd_seq_port_info

# A snd_seq_port_info for a port's address, all else empty.
sub _port_info ($client, $port, $name = '', $cap = 0, $type = 0) {
    return pack $PORT, $client, $port, $name, $cap, $type, $type ? 16 : 0, (0) x 9, '';
}

# What a port can do: be read from, written to (and others subscribe so).
sub readable ($cap) { return ($cap & (CAP_READ | CAP_SUBS_READ)) == (CAP_READ | CAP_SUBS_READ) && !($cap & CAP_NO_EXPORT) }
sub writable ($cap) { return ($cap & (CAP_WRITE | CAP_SUBS_WRITE)) == (CAP_WRITE | CAP_SUBS_WRITE) && !($cap & CAP_NO_EXPORT) }

# A client named $name; dies where there is no sequencer.
sub new ($class, %arg) {
    CORE::open(my $fh, '+<:raw', DEVICE) or die "the ALSA sequencer (" . DEVICE . "): $!\n";
    my $self = bless { fh => $fh, name => $arg{name} // 'Peta::MIDI', decoders => {} }, $class;

    my $buf = pack 'i', 0;
    ioctl($fh, $IOCTL{client_id}, $buf) or die "the sequencer's client id: $!\n";
    $self->{client} = unpack 'i', $buf;
    my $info = pack 'i x184', $self->{client};
    ioctl($fh, $IOCTL{get_client_info}, $info) or die "the sequencer's client info: $!\n";
    substr($info, 8, 64) = pack 'Z64', $self->{name};
    ioctl($fh, $IOCTL{set_client_info}, substr($info, 0, CLIENT_SIZE)) or die "naming the sequencer's client: $!\n";
    return $self;
}

sub handle ($self) { return $self->{fh} }
sub client ($self) { return $self->{client} }

# Who hears of ports coming and going: $callback->('start' or 'exit',
# 'client:port'), once a port of this client's is subscribed to the
# system's announcements (0:1).
sub on_announce ($self, $callback) {
    $self->{announce} = $callback;
    return $self;
}

# A port of this client's: 'in' (others write to it) or 'out' (others read
# from it); its number.
sub create_port ($self, $name, $direction) {
    my $cap = $direction eq 'in' ? CAP_WRITE | CAP_SUBS_WRITE : CAP_READ | CAP_SUBS_READ;
    my $port = _port_info($self->{client}, 0, $name, $cap, TYPE_MIDI_GENERIC | TYPE_APPLICATION);
    ioctl($self->{fh}, $IOCTL{create_port}, $port) or die "the sequencer's port '$name': $!\n";
    return (unpack 'C C', $port)[1];
}

sub delete_port ($self, $port) {
    ioctl($self->{fh}, $IOCTL{delete_port}, _port_info($self->{client}, $port)) or die "deleting the port: $!\n";
    return;
}

# Every port of the other clients (not the system's, not this client's):
# { address ('client:port'), client, port, client_name, port_name, cap }.
# As a function, through a client of its own.
sub ports ($self = undef) {
    my ($fh, $me) = ref $self ? ($self->{fh}, $self->{client}) : (undef, -1);
    if (!$fh) {
        CORE::open($fh, '+<:raw', DEVICE) or return;
    }

    my @found;
    my $client = pack 'i x184', -1;
    while (ioctl($fh, $IOCTL{next_client}, $client)) {
        $client = substr $client, 0, CLIENT_SIZE;
        my ($number, undef, $client_name) = unpack 'i i Z64', $client;
        next if $number == 0 || $number == $me;
        my $port = _port_info($number, 255);    # from before port 0
        while (ioctl($fh, $IOCTL{next_port}, $port)) {
            $port = substr $port, 0, PORT_SIZE;
            my ($c, $p, $port_name, $cap) = unpack 'C C Z64 x2 I', $port;
            push @found, { address => "$c:$p", client => $c, port => $p, client_name => $client_name, port_name => $port_name, cap => $cap };
        }
    }
    return @found;
}

# Two ports connected: what is written to the sender goes to the dest
# ('client:port' each); and parted.
sub subscribe ($self, $sender, $dest) {
    ioctl($self->{fh}, $IOCTL{subscribe}, _subscription($sender, $dest)) or die "connecting $sender to $dest: $!\n";
    return $self;
}

sub unsubscribe ($self, $sender, $dest) {
    ioctl($self->{fh}, $IOCTL{unsubscribe}, _subscription($sender, $dest)) or die "parting $sender and $dest: $!\n";
    return $self;
}

sub _subscription ($sender, $dest) {
    return pack 'C C C C I I C x3 a64', split(/:/, $sender), split(/:/, $dest), 0, 0, 0, '';
}

# What has come in: [ bytes, source ('client:port'), the port of this
# client's it came to ], each a MIDI message (system exclusive perhaps in
# pieces); ports come and gone to on_announce's callback. Waits at most
# $wait seconds for something (0: not at all).
sub read ($self, $wait = 0) {
    my @messages;
    my $fh = $self->{fh};
    my $bits = '';
    vec($bits, fileno $fh, 1) = 1;
    while (select(my $ready = $bits, undef, undef, $wait)) {
        $wait = 0;
        my $got = sysread $fh, my $buf, 65536;
        last unless $got;
        my $pos = 0;
        while ($pos + EVENT_SIZE <= length $buf) {
            my ($type, $flags, $sc, $sp, $dp) = unpack 'C C x2 x8 C C x C', substr($buf, $pos, 16);
            my $data  = substr $buf, $pos + 16, 12;
            my $extra = '';
            $pos += EVENT_SIZE;
            if (($flags & LENGTH_MASK) == LENGTH_VARIABLE) {
                my $len = unpack 'V', $data;
                $extra = substr $buf, $pos, $len;
                $pos += EVENT_SIZE * int(($len + EVENT_SIZE - 1) / EVENT_SIZE);    # padded to whole events
            }
            if ($type == PORT_START || $type == PORT_EXIT) {
                $self->{announce}->($type == PORT_START ? 'start' : 'exit', join ':', unpack 'C C', $data) if $self->{announce};
                next;
            }
            push @messages, map { [ $_, "$sc:$sp", $dp ] } _bytes($type, $data, $extra);
        }
    }
    return @messages;
}

# A sequencer event as MIDI messages (a controller of 14 bits, an RPN or
# NRPN are several).
sub _bytes ($type, $data, $extra) {
    return $extra if $type == SYSEX;
    my $status = $STATUS_OF{$type};
    if ($type == NOTEON || $type == NOTEOFF || $type == KEYPRESS) {
        my ($ch, $key, $velocity) = unpack 'C C C', $data;
        return pack 'C3', $status | $ch, $key & 0x7f, $velocity & 0x7f;
    }
    my ($ch, $param, $value) = unpack 'C x3 I i', $data;
    my $cc = sub (@pairs) { return map { pack 'C3', 0xb0 | $ch, $_->[0] & 0x7f, $_->[1] & 0x7f } @pairs };
    return $cc->([ $param, $value ])                                           if $type == CONTROLLER;
    return pack('C2', $status | $ch, $value & 0x7f)                            if $type == PGMCHANGE || $type == CHANPRESS;
    return pack('C3', $status | $ch, split_bytes($value + 8192))               if $type == PITCHBEND;
    return $cc->([ $param, $value ])                                           if $type == CONTROL14 && $param >= 32;
    return $cc->([ $param, $value >> 7 ], [ $param + 32, $value ])             if $type == CONTROL14;    # coarse and fine
    if ($type == NONREGPARAM || $type == REGPARAM) {
        my ($hi, $lo) = $type == NONREGPARAM ? (99, 98) : (101, 100);
        return $cc->([ $hi, $param >> 7 ], [ $lo, $param ], [ 6, $value >> 7 ], [ 38, $value ]);
    }
    return pack('C3', 0xf2, split_bytes($value))                               if $type == SONGPOS;
    return pack('C2', $status, $value & 0x7f)                                  if $type == SONGSEL || $type == QFRAME;
    return pack('C', $status)                                                  if $status;
    return;
}

# MIDI bytes out of one of this client's ports, to whoever is connected to
# it: whole messages, running status as it may be.
sub send ($self, $port, $bytes) {
    my $decoder = $self->{decoders}{$port} //= Peta::MIDI::Decoder->new;
    $decoder->decode($bytes);
    my $head = sub ($type, $flags = 0) { pack 'C C c C x8 C C C C', $type, $flags, 0, QUEUE_DIRECT, $self->{client}, $port, SUBSCRIBERS, UNKNOWN };
    my $out  = '';
    for my $event ($decoder->events) {
        my ($status, @data) = @{ $event->message };
        if ($status == 0xf0) {
            my $sysex = $event->bytes;
            $out .= $head->(SYSEX, LENGTH_VARIABLE) . pack('V Q', length $sysex, 0) . $sysex;
            next;
        }
        my $type = $TYPE_OF{ $status < 0xf0 ? $status & 0xf0 : $status } // next;
        my $ch   = $status & 0x0f;
        my $data = $type == NOTEON || $type == NOTEOFF || $type == KEYPRESS ? pack('C C C C I', $ch, @data[ 0, 1 ], 0, 0)
                 : $type == CONTROLLER                                   ? pack('C x3 I i', $ch, @data[ 0, 1 ])
                 : $type == PGMCHANGE || $type == CHANPRESS              ? pack('C x3 I i', $ch, 0, $data[0])
                 : $type == PITCHBEND                                    ? pack('C x3 I i', $ch, 0, $event->value)
                 : $type == SONGPOS                                      ? pack('C x3 I i', 0, 0, $event->position)
                 : $type == SONGSEL || $type == QFRAME                   ? pack('C x3 I i', 0, 0, $data[0])
                 :                                                         pack('x12');
        $out .= $head->($type) . pack 'a12', $data;    # every event's data is 12 bytes
    }
    syswrite($self->{fh}, $out) // die "sending MIDI: $!\n" if length $out;
    return $self;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::ALSA - a client of the ALSA sequencer, with no library

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $alsa = Peta::MIDI::ALSA->new(name => 'my program');
    my $in   = $alsa->create_port('in', 'in');
    my $out  = $alsa->create_port('out', 'out');
    my ($synth) = grep { Peta::MIDI::ALSA::writable($_->{cap}) && $_->{client_name} =~ /FLUID/ } $alsa->ports;
    $alsa->subscribe($alsa->client . ":$out", $synth->{address});
    $alsa->send($out, "\x90\x3c\x64");
    for my $message ($alsa->read(1)) {
        my ($bytes, $source, $port) = @$message;
    }

=head1 DESCRIPTION

The kernel's MIDI router through its device: ports of this client's, the
other clients' ports, connections between them, and MIDI bytes in and
out. L<Peta::MIDI::Device> is built on it, and so is
L<Peta::Synth::Input>.

=head1 METHODS

=head2 new, client, handle

C<< new(name => ...) >> (dies where there is no sequencer); this client's
number; its file handle (for C<select> or an event loop).

=head2 create_port, delete_port

C<create_port($name, 'in' or 'out')>: a port others write to, or read
from; its number.

=head2 ports, readable, writable

The other clients' ports (also as a function): hashes of C<address>,
C<client>, C<port>, C<client_name>, C<port_name>, C<cap>; C<readable($cap)>
and C<writable($cap)> say what they can do.

=head2 subscribe, unsubscribe

C<subscribe($sender, $dest)>: what the sender port gives goes to the dest
port (C<client:port> each).

=head2 on_announce

C<on_announce($callback)>: who hears of ports coming and going,
C<< $callback->('start' or 'exit', 'client:port') >>, once a port of this
client's is subscribed to the system's announcements (0:1).

=head2 read, send

C<read($wait)>: what has come in, as C<[bytes, source, port]>, waiting at
most C<$wait> seconds. C<on_announce(sub ($what, $address) {...})>: ports
coming (C<start>) and going (C<exit>), once a port of this client's is
subscribed to the system's announcements (0:1). C<send($port, $bytes)>: MIDI messages out of
a port of this client's to whoever is connected to it.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

package Peta::Synth::MIDI;
# ABSTRACT: Standard MIDI Files, read and written

# Standard MIDI Files (SMF, formats 0, 1 and 2): read into tracks of events
# at their tick, and written back from them; and single messages, as a
# device sends them. What the events mean (notes, controllers, system
# exclusive) is Peta::Synth::Synth's business; this module only knows the
# bytes.
#
# An event is a hash:
#
#   { tick => 960, track => 1, type => 'note_on', channel => 0, key => 60, velocity => 100 }
#
#   note_off, note_on     channel key velocity
#   key_pressure          channel key value
#   controller            channel number value
#   program               channel program
#   channel_pressure      channel value
#   pitch_bend            channel value        (-8192 .. 8191, 0 is centre)
#   meta                  meta (the type byte) data (the bytes)
#   tempo                 usec                 (microseconds per quarter note)
#   sysex                 data                 (the bytes after F0 or F7)
#
# Tempo is a meta event that is common enough to be its own type; every other
# meta event (text, time signature, end of track, ...) stays 'meta'.

use v5.36;

our $VERSION = '0.2610180';

# The channel messages, 0x80 .. 0xEF by the status' high nibble: their
# type and how many data bytes they take.
my @CHANNEL_TYPE = (
    [ note_off         => 2 ],
    [ note_on          => 2 ],
    [ key_pressure     => 2 ],
    [ controller       => 2 ],
    [ program          => 1 ],
    [ channel_pressure => 1 ],
    [ pitch_bend       => 2 ],
);

# The data bytes of the system common messages F1 .. F6.
my %COMMON_SIZE = (0xf1 => 1, 0xf2 => 2, 0xf3 => 1, 0xf4 => 0, 0xf5 => 0, 0xf6 => 0);

# How many data bytes follow a status byte (0 for those that have none).
sub data_bytes ($status) {
    return $CHANNEL_TYPE[ ($status >> 4) - 8 ][1] if $status >= 0x80 && $status < 0xf0;
    return $COMMON_SIZE{$status} // 0;
}

sub new ($class, %arg) {
    return bless {
        format   => $arg{format}   // 1,
        division => $arg{division} // 480,
        tracks   => $arg{tracks}   // [],
    }, $class;
}

sub read ($class, $file) {
    open my $fh, '<:raw', $file or die "cannot read '$file': $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $class->parse($bytes, $file);
}

sub parse ($class, $bytes, $name = 'the data') {
    my $pos = 0;
    # A RIFF wrapper (.rmi) holds the SMF in its 'data' chunk.
    if (substr($bytes, 0, 4) eq 'RIFF' && substr($bytes, 8, 4) eq 'RMID') {
        my $at = index($bytes, 'MThd');
        die "$name: a RIFF MIDI file without an SMF in it\n" if $at < 0;
        $pos = $at;
    }
    die "$name: not a Standard MIDI File\n" unless substr($bytes, $pos, 4) eq 'MThd';
    my ($length, $format, $count, $division) = unpack 'N n n n', substr($bytes, $pos + 4, 10);
    die "$name: header too short\n" if $length < 6;
    $pos += 8 + $length;

    my $self = $class->new(format => $format, division => $division);
    while ($pos + 8 <= length $bytes) {
        my ($id, $size) = unpack 'a4 N', substr($bytes, $pos, 8);
        $pos += 8;
        $size = length($bytes) - $pos if $pos + $size > length $bytes;    # a cut-off last track
        push @{ $self->{tracks} }, _track(substr($bytes, $pos, $size), scalar @{ $self->{tracks} }, $name)
            if $id eq 'MTrk';
        $pos += $size;
    }
    warn "$name: header says $count tracks, the file has " . @{ $self->{tracks} } . "\n"
        if @{ $self->{tracks} } != $count;
    return $self;
}

sub _vlq ($bytes, $pos) {
    my $value = 0;
    for (1 .. 4) {
        my $byte = ord substr($$bytes, $$pos++, 1);
        $value = ($value << 7) | ($byte & 0x7f);
        return $value if $byte < 0x80;
    }
    return $value;
}

sub _track ($bytes, $track, $name) {
    my ($pos, $tick, $status, @events) = (0, 0, 0);
    my $end = length $bytes;
    while ($pos < $end) {
        $tick += _vlq(\$bytes, \$pos);
        last if $pos >= $end;
        my $byte = ord substr($bytes, $pos, 1);
        if ($byte >= 0x80) {
            $pos++;
            $status = $byte if $byte < 0xf0;    # running status survives meta and sysex (as most readers have it)
        }
        else {
            die "$name: track $track: data byte without a status at offset $pos\n" unless $status;
            $byte = $status;
        }

        if ($byte == 0xff) {
            my $meta = ord substr($bytes, $pos++, 1);
            my $len  = _vlq(\$bytes, \$pos);
            my $data = substr($bytes, $pos, $len);
            $pos += $len;
            if ($meta == 0x51 && $len == 3) {
                push @events, { tick => $tick, track => $track, type => 'tempo', usec => unpack('N', "\0$data") };
            }
            else {
                push @events, { tick => $tick, track => $track, type => 'meta', meta => $meta, data => $data };
            }
            last if $meta == 0x2f;
        }
        elsif ($byte == 0xf0 || $byte == 0xf7) {
            my $len = _vlq(\$bytes, \$pos);
            push @events, { tick => $tick, track => $track, type => 'sysex', data => substr($bytes, $pos, $len) };
            $pos += $len;
        }
        elsif ($byte >= 0xf1) {
            # System common and real-time bytes do not belong in a file; skip their data.
            $pos += data_bytes($byte);
        }
        else {
            my $size = data_bytes($byte);
            my ($one, $two) = unpack 'C2', substr($bytes, $pos, $size) . "\0";
            $pos += $size;
            push @events, { tick => $tick, track => $track, %{ _channel_event($byte, $one, $two) } };
        }
    }
    return \@events;
}

# A channel message's event from its status and data bytes.
sub _channel_event ($status, $one, $two) {
    my $type  = $CHANNEL_TYPE[ ($status >> 4) - 8 ][0];
    my %event = (type => $type, channel => $status & 0x0f);
    if    ($type eq 'note_on' && $two == 0) { @event{qw(type key velocity)} = ('note_off', $one, 64) }
    elsif ($type eq 'note_on' || $type eq 'note_off') { @event{qw(key velocity)} = ($one, $two) }
    elsif ($type eq 'key_pressure')     { @event{qw(key value)}     = ($one, $two) }
    elsif ($type eq 'controller')       { @event{qw(number value)}  = ($one, $two) }
    elsif ($type eq 'program')          { $event{program}           = $one }
    elsif ($type eq 'channel_pressure') { $event{value}             = $one }
    else                                { $event{value} = (($two << 7) | $one) - 8192 }
    return \%event;
}

# One message as a device sends it (its bytes, status first, a system
# exclusive one whole from F0 to F7): its event, or undef for what is not
# a channel's or system exclusive (clock, active sensing, ...) or is cut short.
sub message ($bytes) {
    my ($status, @data) = unpack 'C*', $bytes;
    return unless defined $status;
    return { type => 'sysex', data => substr($bytes, 1) } if $status == 0xf0;
    return if $status < 0x80 || $status >= 0xf0;

    my $size = data_bytes($status);
    return if @data < $size || grep { $_ > 0x7f } @data[ 0 .. $size - 1 ];
    return _channel_event($status, $data[0], $data[1] // 0);
}

sub format   ($self) { return $self->{format} }
sub division ($self) { return $self->{division} }
sub tracks   ($self) { return $self->{tracks} }

# All events of all tracks in the order they take effect, each with its time
# in seconds ('time'), the tempo map applied; copies, the tracks are left as
# they are. Events at the same tick keep the order of the file: track by
# track, and within a track as they were written (a note off written before
# a pedal at the same tick ends the note; written after, the pedal holds it).
# Format 2 files hold independent sequences; they are played one after another.
sub timeline ($self) {
    my $tracks = $self->{tracks};
    my $offset = 0;    # in format 2, where this track's sequence begins
    my @keyed;         # [ tick, track, index in the track, event ]
    for my $t (0 .. $#$tracks) {
        my $last  = 0;
        my $index = 0;
        for my $event (@{ $tracks->[$t] }) {
            my $tick = $event->{tick} + $offset;
            push @keyed, [ $tick, $t, $index++, { %$event, tick => $tick, track => $t } ];
            $last = $event->{tick} if $event->{tick} > $last;
        }
        $offset += $last if $self->{format} == 2;
    }
    my @sorted = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] } @keyed;
    my @events = map { $_->[3] } @sorted;

    my $division = $self->{division};
    if ($division & 0x8000) {
        # SMPTE: frames per second (as a negative byte) and ticks per frame; no tempo.
        my $fps = 256 - ($division >> 8);
        $fps = 29.97 if $fps == 29;
        my $per_tick = 1 / ($fps * ($division & 0xff));
        $_->{time} = $_->{tick} * $per_tick for @events;
        return \@events;
    }
    my ($tick, $time, $per_tick) = (0, 0, 0.5 / $division);    # 120 bpm until said otherwise
    for my $event (@events) {
        $time += ($event->{tick} - $tick) * $per_tick;
        $tick = $event->{tick};
        $event->{time} = $time;
        $per_tick = $event->{usec} / 1e6 / $division if $event->{type} eq 'tempo' && $event->{usec};
    }
    return \@events;
}

# Writing: the counterpart of read, for what composes in Perl and for the tests.

# A variable-length quantity: seven bits a byte, the high bit set on all
# but the last.
sub _vlq_bytes ($value) {
    my $bytes = chr($value & 0x7f);
    $bytes = chr(0x80 | ($value & 0x7f)) . $bytes while ($value >>= 7);
    return $bytes;
}

# An event as the bytes of a track (running status not used).
sub _event_bytes ($event) {
    my $type = $event->{type};
    my $ch   = $event->{channel} // 0;
    return "\xff\x51\x03" . substr(pack('N', $event->{usec}), 1) if $type eq 'tempo';
    return "\xff" . chr($event->{meta}) . _vlq_bytes(length $event->{data}) . $event->{data} if $type eq 'meta';
    return "\xf0" . _vlq_bytes(length $event->{data}) . $event->{data} if $type eq 'sysex';
    return pack 'C3', 0x80 | $ch, $event->{key}, $event->{velocity} // 64    if $type eq 'note_off';
    return pack 'C3', 0x90 | $ch, $event->{key}, $event->{velocity}          if $type eq 'note_on';
    return pack 'C3', 0xa0 | $ch, $event->{key}, $event->{value}             if $type eq 'key_pressure';
    return pack 'C3', 0xb0 | $ch, $event->{number}, $event->{value}          if $type eq 'controller';
    return pack 'C2', 0xc0 | $ch, $event->{program}                          if $type eq 'program';
    return pack 'C2', 0xd0 | $ch, $event->{value}                            if $type eq 'channel_pressure';
    if ($type eq 'pitch_bend') {
        my $value = $event->{value} + 8192;
        return pack 'C3', 0xe0 | $ch, $value & 0x7f, $value >> 7;
    }
    die "cannot write an event of type '$type'\n";
}

# The file as bytes. Each track gets one end of track, at its last event.
sub bytes ($self) {
    my $out = pack 'a4 N n n n', 'MThd', 6, $self->{format}, scalar @{ $self->{tracks} }, $self->{division};
    for my $track (@{ $self->{tracks} }) {
        # In tick order; events at the same tick in the order they are given.
        my @indexed = map { [ $_, $track->[$_] ] } 0 .. $#$track;
        my @events  = map { $_->[1] } sort { $a->[1]{tick} <=> $b->[1]{tick} || $a->[0] <=> $b->[0] } @indexed;
        my ($tick, $body) = (0, '');
        for my $event (@events) {
            next if $event->{type} eq 'meta' && $event->{meta} == 0x2f;
            $body .= _vlq_bytes($event->{tick} - $tick) . _event_bytes($event);
            $tick = $event->{tick};
        }
        $body .= "\0\xff\x2f\0";
        $out  .= pack('a4 N', 'MTrk', length $body) . $body;
    }
    return $out;
}

sub write ($self, $file) {
    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    print {$fh} $self->bytes;
    close $fh or die "cannot write '$file': $!\n";
    return $file;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::MIDI - Standard MIDI Files, read and written

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $midi = Peta::Synth::MIDI->read('song.mid');
    for my $event (@{ $midi->timeline }) {
        printf "%8.3f %s\n", $event->{time}, $event->{type};
    }

    my $out = Peta::Synth::MIDI->new(division => 480, tracks => [[
        { tick => 0,   type => 'note_on',  channel => 0, key => 60, velocity => 100 },
        { tick => 480, type => 'note_off', channel => 0, key => 60 },
    ]]);
    $out->write('c.mid');

=head1 DESCRIPTION

Reads and writes Standard MIDI Files of formats 0, 1 and 2, and RIFF MIDI
(C<.rmi>) files. A file is a list of tracks, a track a list of events at
their tick. The event types and their fields are listed at the top of the
source; a C<note_on> with velocity 0 is read as a C<note_off>.

=head1 METHODS

=head2 new

C<< new(format => 1, division => 480, tracks => [...]) >>: a file in memory.

=head2 read

C<< read($file) >>: the file, parsed. Dies if it is not a MIDI file.

=head2 parse

C<< parse($bytes, $name) >>: the same from the bytes of a file.

=head2 message

C<Peta::Synth::MIDI::message($bytes)>: one message as a device sends it,
as an event (C<sysex> with what follows F0), or undef where it is no
channel or system exclusive message.

=head2 data_bytes

C<data_bytes($status)>: how many data bytes follow a status byte: those of
a channel message (1 or 2) or of a system common one (0 to 2).

=head2 format, division, tracks

The SMF format, the division (ticks per quarter note, or SMPTE timing when
the top bit is set) and the tracks.

=head2 timeline

All events of all tracks in the order they take effect, each with its time
in seconds in C<time>, the tempo map applied (copies: the tracks are not
changed). Events at the same tick keep the order of the file, track by
track: what a file says first happens first. The sequences of a format 2
file are played one after another.

=head2 bytes, write

The file as bytes, or written to C<$file>. Events at the same tick are written in
the order they are given.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

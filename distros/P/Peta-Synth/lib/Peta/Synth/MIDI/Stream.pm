package Peta::Synth::MIDI::Stream;
# ABSTRACT: MIDI bytes as a device sends them, into events

# A stream of MIDI bytes, as a device sends them, into events: running
# status, system exclusive between F0 and F7, real-time bytes (clock,
# active sensing) anywhere and ignored but System Reset (FF, a reset as GM
# System On is one), system common messages skipped.
# Bytes may come in any pieces; a message cut between two is completed by
# the next.

use v5.36;
use Peta::Synth::MIDI;

our $VERSION = '0.2610180';

sub new ($class) {
    return bless {
        status => 0,        # the running status
        data   => '',       # its data bytes so far
        need   => 0,        # and how many it takes
        skip   => 0,        # data bytes of a system common message still to come
        sysex  => undef,    # a system exclusive message so far, while in one
    }, $class;
}

# The events the bytes complete.
sub feed ($self, $bytes) {
    my @events;
    for my $byte (unpack 'C*', $bytes) {
        if ($byte >= 0xf8) {
            # Real time: ignored, but a reset.
            push @events, { type => 'sysex', data => "\x7e\x7f\x09\x01\xf7" } if $byte == 0xff;
            next;
        }

        if ($byte == 0xf0) {
            # System exclusive begins; it ends running status.
            @$self{qw(sysex status skip)} = ('', 0, 0);
        }
        elsif ($byte == 0xf7) {
            push @events, Peta::Synth::MIDI::message("\xf0$self->{sysex}\xf7") if defined $self->{sysex};
            $self->{sysex} = undef;
        }
        elsif ($byte >= 0xf1) {
            # System common: its data bytes are skipped.
            @$self{qw(sysex status skip)} = (undef, 0, Peta::Synth::MIDI::data_bytes($byte));
        }
        elsif ($byte >= 0x80) {
            # A channel message's status.
            @$self{qw(sysex status data skip)} = (undef, $byte, '', 0);
            $self->{need} = Peta::Synth::MIDI::data_bytes($byte);
        }
        elsif (defined $self->{sysex}) { $self->{sysex} .= chr $byte }
        elsif ($self->{skip})          { $self->{skip}-- }
        elsif ($self->{status}) {
            $self->{data} .= chr $byte;
            next if length $self->{data} < $self->{need};
            my $event = Peta::Synth::MIDI::message(chr($self->{status}) . $self->{data});
            push @events, $event if $event;
            $self->{data} = '';    # running status: the next data bytes are a message of the same status
        }
    }
    return @events;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::MIDI::Stream - MIDI bytes as a device sends them, into events

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $stream = Peta::Synth::MIDI::Stream->new;
    $synth->play($_) for $stream->feed($bytes);

=head1 DESCRIPTION

Running status, system exclusive, real-time bytes in between (ignored,
but a system reset, FF, which is taken as GM System On); the events are
L<Peta::Synth::MIDI>'s.

=head1 METHODS

=head2 new, feed

C<new>: a stream with nothing in it yet; C<feed($bytes)>: the events the
bytes complete, what is not whole yet kept for the next bytes.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

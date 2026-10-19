package Peta::Synth::Input;
# ABSTRACT: MIDI as it is played: the ALSA sequencer, raw devices

# MIDI coming in as it is played: a port of a client of the ALSA sequencer
# (Peta::MIDI::ALSA: the kernel's MIDI router, no library). Keyboards on
# USB, MIDI interfaces, software keyboards and sequencers are its clients;
# PipeWire bridges its own MIDI to it. The port is connected to the sources
# it is told (all of them, by default, and those that appear later); what
# comes from each is read as MIDI bytes (Peta::Synth::MIDI::Stream), a
# controller of 14 bits, an RPN or NRPN as their controllers.
#
# A raw MIDI device or a pipe (a path) is read as bytes instead:
# Peta::Synth::Input::Raw.

use v5.36;
use Peta::MIDI::ALSA;
use Peta::Synth::MIDI::Stream;

our $VERSION = '0.2610180';

# What to read MIDI from: undef or 'all' (every source there is and comes),
# 'none' (a port others connect to), a path (a raw device or a pipe), or
# sources: 'client:port' or a part of a client's or port's name, several
# joined by commas.
sub open ($class, $spec = undef) {
    $spec //= 'all';
    if ($spec =~ m{\A/}) {
        require Peta::Synth::Input::Raw;
        return Peta::Synth::Input::Raw->new($spec);
    }
    my $self = $class->new;
    if    ($spec eq 'all')  { $self->follow }
    elsif ($spec ne 'none') { $self->connect($_) for split /\s*,\s*/, $spec }
    return $self;
}

sub new ($class, %arg) {
    my $alsa = Peta::MIDI::ALSA->new(name => $arg{name} // 'Peta::Synth');
    my $self = bless {
        alsa      => $alsa,
        port      => $alsa->create_port('MIDI in', 'in'),
        streams   => {},    # each source's bytes, by address
        connected => {},    # the sources, by address
    }, $class;
    $alsa->on_announce(sub ($what, $address) { $self->_announced($what, $address) });
    return $self;
}

sub handle    ($self) { return $self->{alsa}->handle }
sub address   ($self) { return $self->{alsa}->client . ":$self->{port}" }
sub connected ($self) { return sort keys %{ $self->{connected} } }

# Every port others can read MIDI from (not the system's, not this
# client's): { address, client, port } by name.
sub sources ($self = undef) {
    my @ports = ref $self ? $self->{alsa}->ports : Peta::MIDI::ALSA::ports();
    return map { +{ address => $_->{address}, client => $_->{client_name}, port => $_->{port_name} } }
        grep { Peta::MIDI::ALSA::readable($_->{cap}) } @ports;
}

# Connects a source to this client's port: 'client:port', or the first
# source whose client or port name holds the text.
sub connect ($self, $source) {
    my $address = $source =~ /\A\d+:\d+\z/ ? $source : undef;
    if (!defined $address) {
        my ($found) = grep { index(lc "$_->{client} $_->{port}", lc $source) >= 0 } $self->sources;
        die "no MIDI source '$source' (peta-synth inputs lists them)\n" if !$found;
        $address = $found->{address};
    }
    $self->{alsa}->subscribe($address, $self->address);
    $self->{connected}{$address} = 1;
    return $self;
}

# Every source, and those that come later (announced by the system's
# port 0:1); not the kernel's loopback (Midi Through).
sub follow ($self) {
    $self->{follow} = 1;
    for my $source ($self->sources) {
        next if $source->{client} =~ /\AMidi Through/;
        eval { $self->connect($source->{address}); 1 };
    }
    eval { $self->{alsa}->subscribe('0:1', $self->address); 1 };
    return $self;
}

# A port come (connected, following, if it is a source) or gone.
sub _announced ($self, $what, $address) {
    if ($what eq 'exit') {
        delete $self->{connected}{$address};
        return;
    }
    return if !$self->{follow};
    eval { $self->connect($address); 1 } if grep { $_->{address} eq $address } $self->sources;
    return;
}

# What has come in, as Peta::Synth::MIDI's events; waits at most $wait
# seconds for something (0: not at all).
sub events ($self, $wait = 0) {
    return map {
        my ($bytes, $source) = @$_;
        ($self->{streams}{$source} //= Peta::Synth::MIDI::Stream->new)->feed($bytes);
    } $self->{alsa}->read($wait);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Input - MIDI as it is played: the ALSA sequencer, raw devices

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $in = Peta::Synth::Input->open('all');      # or 'none', '20:0', 'Keystation', '/dev/snd/midiC1D0'
    while (1) {
        $synth->play($_) for $in->events;
        ...
    }

    say "$_->{address}  $_->{client}: $_->{port}" for Peta::Synth::Input::sources();

=head1 DESCRIPTION

A port named C<MIDI in> of a client of the ALSA sequencer
(L<Peta::MIDI::ALSA>), that sources are connected to. C<open> takes what
to read: C<all> (every source, and those plugged in later), C<none> (only
the port, for others to connect), sources by address or name (joined by
commas), or the path of a raw MIDI device or pipe
(L<Peta::Synth::Input::Raw>).

=head2 open, new

C<open($what)>: an input reading what is said (C<all> by default); a
raw device's or pipe's path gives a L<Peta::Synth::Input::Raw>.
C<< new(name => 'Peta::Synth') >>: the client and its port, connected to
nothing yet.

=head2 events

C<events($wait)>: what has come in, as L<Peta::Synth::MIDI>'s events,
waiting at most C<$wait> seconds for the first.

=head2 sources, connect, follow, connected, address, handle

The sources there are; connecting one; connecting all, and those to come;
those connected; this client's port (C<client:port>); its file handle (for
C<select>).

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

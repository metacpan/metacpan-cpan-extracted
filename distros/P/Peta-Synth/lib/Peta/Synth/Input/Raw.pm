package Peta::Synth::Input::Raw;
# ABSTRACT: MIDI bytes from a device or a pipe

# MIDI read as bytes from a path: a raw MIDI device (/dev/snd/midiC*D*,
# one per hardware port), a named pipe, a file. The same interface as
# Peta::Synth::Input.

use v5.36;
use Peta::Synth::MIDI::Stream;

our $VERSION = '0.2610180';

sub new ($class, $path) {
    open my $fh, '<:raw', $path or die "MIDI from '$path': $!\n";
    return bless { fh => $fh, path => $path, stream => Peta::Synth::MIDI::Stream->new }, $class;
}

sub handle    ($self) { return $self->{fh} }
sub address   ($self) { return $self->{path} }
sub connected ($self) { return $self->{path} }

# What has come in; waits at most $wait seconds for something (0: not at all).
sub events ($self, $wait = 0) {
    my @events;
    my $bits = '';
    vec($bits, fileno $self->{fh}, 1) = 1;
    while (select(my $ready = $bits, undef, undef, $wait)) {
        $wait = 0;
        my $got = sysread $self->{fh}, my $buf, 4096;
        last if !$got;

        push @events, $self->{stream}->feed($buf);
    }
    return @events;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Input::Raw - MIDI bytes from a device or a pipe

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $in = Peta::Synth::Input::Raw->new('/dev/snd/midiC1D0');
    $synth->play($_) for $in->events;

=head1 DESCRIPTION

What L<Peta::Synth::Input> reads when it is given a path.

=head1 METHODS

=head2 new

C<new($path)>: the device or pipe, opened for reading.

=head2 events

C<events($wait)>: what has come, as L<Peta::Synth::MIDI>'s events, waiting
at most C<$wait> seconds for the first; as L<Peta::Synth::Input>'s.

=head2 handle, address, connected

Its file handle (for C<select>); its path, which is also what is
connected.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

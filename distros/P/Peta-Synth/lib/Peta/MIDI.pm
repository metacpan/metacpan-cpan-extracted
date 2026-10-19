package Peta::MIDI;
# ABSTRACT: MIDI in and out in real time, as MIDI::RtMidi::FFI has it, with no library

# MIDI in and out, in real time, with no library: devices and ports as
# MIDI::RtMidi::FFI::Device has them, on the ALSA sequencer.

use v5.36;

our $VERSION = '0.2610180';

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI - MIDI in and out in real time, as MIDI::RtMidi::FFI has it, with no library

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::MIDI::Device;

    my $out = Peta::MIDI::Device->new(type => 'out', name => 'arpeggios');
    $out->open_port_by_name(qr/FLUID|TiMidity/i);
    $out->note_on(0, 60, 100);

    my $in = Peta::MIDI::Device->new(type => 'in');
    $in->open_port_by_name(qr/keyboard/i);
    $in->set_callback_decoded(sub ($dt, $msg, $event) { say "@$event" });
    $in->dispatch(60);    # or any AnyEvent loop: EV, Event, IO::Async, Coro

=head1 DESCRIPTION

The devices of L<MIDI::RtMidi::FFI::Device> (its ports, by number, name
or pattern, virtual ports; its messages as bytes or decoded events; its
callbacks, queue and handle; its senders, RPN, NRPN and panic), built on
the ALSA sequencer through its device with no library, so on perl5 and
pperl alike, on Linux.

=over

=item L<Peta::MIDI::Device>, L<Peta::MIDI::Device::In>, L<Peta::MIDI::Device::Out>

Devices and ports; an input; an output.

=item L<Peta::MIDI::Event>, L<Peta::MIDI::Decoder>, L<Peta::MIDI::Encoder>

MIDI messages as events (MIDI::Stream's names, MIDI::Event's besides);
bytes into events (running status, system exclusive, real time anywhere,
controllers of 14 bits, the clock's tempo) and back.

=item L<Peta::MIDI::ALSA>

The ALSA sequencer's client: ports, connections, bytes in and out.

=back

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

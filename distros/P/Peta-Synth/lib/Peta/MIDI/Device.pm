package Peta::MIDI::Device;
# ABSTRACT: MIDI devices as MIDI::RtMidi::FFI::Device has them, on the ALSA sequencer

# MIDI devices as MIDI::RtMidi::FFI::Device has them, on the ALSA
# sequencer (Peta::MIDI::ALSA; no library): a device is an input
# (Peta::MIDI::Device::In) or an output (::Out) with one port of its own,
# opened onto another client's port (by number, name, pattern or a list of
# them) or open to all as a virtual port. Ports are numbered as the
# sequencer lists them, and named 'client:port client_number:port_number',
# as RtMidi names them.

use v5.36;
use Carp qw(croak);
use Time::HiRes ();
use Peta::MIDI::ALSA;
use Peta::MIDI::Event;

our $VERSION = '0.2610180';

# A device: new(type => 'in' or 'out' (the default), name => ...), or
# Peta::MIDI::Device::In->new(...) and ::Out->new(...).
sub new ($class, %arg) {
    if ($class eq __PACKAGE__) {
        my $type = delete($arg{type}) // 'out';
        croak "a device is 'in' or 'out', not '$type'" if $type ne 'in' && $type ne 'out';
        my $kind = $type eq 'in' ? 'Peta::MIDI::Device::In' : 'Peta::MIDI::Device::Out';
        (my $file = "$kind.pm") =~ s{::}{/}g;
        require $file;
        return $kind->new(%arg);
    }
    croak "'type' is for Peta::MIDI::Device->new only" if exists $arg{type};
    my $api = $arg{api_name} // $arg{api} // 'alsa';
    croak "the MIDI API here is ALSA, not '$api'" if $api ne 'alsa' && $api ne 'unspecified';

    my $self = bless { name => $arg{name} // "Peta::MIDI Client $class" }, $class;
    $self->{alsa} = Peta::MIDI::ALSA->new(name => $self->{name});
    $self->_build(%arg);
    return $self;
}

sub _build ($self, %arg) { return }

sub name              ($self) { return $self->{name} }
sub port_name         ($self) { return $self->{port_name} }
sub connected_to      ($self) { return $self->{connected_to} }
sub connected_to_name ($self) { return $self->{connected_to_name} }
sub ok                ($self, $ok = undef) { return 1 }
sub msg               ($self) { return '' }
sub get_current_api   ($self) { return 'alsa' }
sub get_compiled_api  ($self) { return ('alsa') }

sub name_to_midi_event ($self, $name)   { return Peta::MIDI::Event::name_to_midi_event($name) }
sub name_from_midi_event ($self, $name) { return Peta::MIDI::Event::name_from_midi_event($name) }

# The ports a device of this kind can open (an input those that can be
# read, an output those that can be written), in the sequencer's order.
sub _ports ($self) {
    my $can = $self->_direction eq 'in' ? \&Peta::MIDI::ALSA::readable : \&Peta::MIDI::ALSA::writable;
    return sort { $a->{client} <=> $b->{client} || $a->{port} <=> $b->{port} } grep { $can->($_->{cap}) } $self->{alsa}->ports;
}

sub _port_name ($port) { return "$port->{client_name}:$port->{port_name} $port->{address}" }

sub get_port_count ($self) {
    my @ports = $self->_ports;
    return scalar @ports;
}

sub get_port_name ($self, $number) {
    my $port = ($self->_ports)[$number] // return undef;
    return _port_name($port);
}

sub get_all_port_nums ($self) {
    my @ports = $self->_ports;
    return { map { $_ => _port_name($ports[$_]) } 0 .. $#ports };
}

sub get_all_port_names ($self) { return { reverse %{ $self->get_all_port_nums } } }

# The ports' numbers whose names are the name, match the pattern, or (a
# list) any of them, in that order.
sub get_ports_by_name ($self, $which) {
    return map { $self->get_ports_by_name($_) } @$which if ref $which eq 'ARRAY';
    my $names = $self->get_all_port_nums;
    return grep {
        ref $which eq 'Regexp' ? $names->{$_} =~ $which : $names->{$_} eq $which
    } sort { $a <=> $b } keys %$names;
}

sub print_ports ($self, $handle = \*STDOUT) {
    my $names = $self->get_all_port_nums;
    print {$handle} "$_: $names->{$_}\n" for sort { $a <=> $b } keys %$names;
    return;
}

# A port of this device's own, connected to port $number.
sub open_port ($self, $number, $name = 'Peta::MIDI') {
    my $port = ($self->_ports)[$number] // croak "Invalid port number ($number)";
    $self->close_port;
    my $mine = $self->{alsa}->create_port($name, $self->_direction);
    my $address = $self->{alsa}->client . ":$mine";
    my ($sender, $dest) = $self->_direction eq 'in' ? ($port->{address}, $address) : ($address, $port->{address});
    $self->{alsa}->subscribe($sender, $dest);
    @$self{qw(port port_name connected_to connected_to_name subscription)} = ($mine, $name, $number, _port_name($port), [ $sender, $dest ]);
    return !!1;
}

sub open_port_by_name ($self, $which, $name = Time::HiRes::time()) {
    my ($number) = $self->get_ports_by_name($which);
    croak 'No available device found matching supplied criteria' if !defined $number;
    return $self->open_port($number, $name);
}

# A port of this device's own that others connect to.
sub open_virtual_port ($self, $name) {
    $self->close_port;
    @$self{qw(port port_name)} = ($self->{alsa}->create_port($name, $self->_direction), $name);
    return !!1;
}

sub close_port ($self) {
    return if !defined $self->{port};
    eval { $self->{alsa}->unsubscribe(@{ $self->{subscription} }); 1 } if $self->{subscription};
    eval { $self->{alsa}->delete_port($self->{port}); 1 };
    delete @$self{qw(port subscription connected_to connected_to_name)};
    return !!1;
}

sub DESTROY ($self) { $self->close_port if $self->{alsa} }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MIDI::Device - MIDI devices as MIDI::RtMidi::FFI::Device has them, on the ALSA sequencer

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::MIDI::Device;

    my $out = Peta::MIDI::Device->new(type => 'out', name => 'my program');
    $out->print_ports;
    $out->open_port_by_name(qr/FLUID/i);
    $out->program_change(0, 19);
    $out->note_on(0, 60, 100);

    my $in = Peta::MIDI::Device->new(type => 'in');
    $in->open_virtual_port('my input');
    $in->set_callback_decoded(sub ($dt, $msg, $event) { say "@$event" });
    $in->dispatch(10);

=head1 DESCRIPTION

The devices and ports of L<MIDI::RtMidi::FFI::Device>, its methods and
their behaviour, built on the ALSA sequencer through its device with no
library (L<Peta::MIDI::ALSA>), so on perl5 and pperl alike, on Linux. An
input is L<Peta::MIDI::Device::In>, an output L<Peta::MIDI::Device::Out>.
Ports are numbered as the sequencer lists them (the readable ones for an
input, the writable for an output) and named C<client:port c:p>.

=head1 METHODS

=head2 new

C<< new(type => 'in' or 'out', name => ..., api_name => 'alsa') >>;
C<Peta::MIDI::Device::In-E<gt>new> and C<::Out-E<gt>new> without C<type>.

=head2 get_port_count, get_port_name, get_all_port_nums, get_all_port_names, get_ports_by_name, print_ports

The ports there are: how many, a number's name, C<< { number => name } >>
and C<< { name => number } >>, the numbers whose names are a name, match a
pattern or any of a list, all printed.

=head2 open_port, open_port_by_name, open_virtual_port, close_port

C<open_port($number, $name)>: a port of the device's own, named C<$name>,
connected to that port; C<open_port_by_name($which, $name)> the first that
matches; C<open_virtual_port($name)> a port others connect to;
C<close_port> parts and removes it.

=head2 name, port_name, connected_to, connected_to_name, ok, msg, get_current_api, get_compiled_api

The device's name, its port's, the port it is connected to (number and
name); C<ok> (true) and C<msg> (empty) as RtMidi has them; the API,
C<alsa>.

=head2 name_to_midi_event, name_from_midi_event

MIDI::Event's names for events, and back.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut

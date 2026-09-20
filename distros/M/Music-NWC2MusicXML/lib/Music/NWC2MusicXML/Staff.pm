package Music::NWC2MusicXML::Staff;

use strict;
use warnings;

our $VERSION = '0.001.1';

use Carp qw(croak carp);
use Readonly;
use Scalar::Util qw(blessed);
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Music::NWC2MusicXML::Event;

Readonly::Hash my %MESSAGES => (
	error_bad_event  => 'add_event: argument must be a Music::NWC2MusicXML::Event, got: %s',
	error_internal   => 'Internal error: %s',
);

# Event types that constitute a sounding (or structurally significant) event
# for the purpose of has_notes().  Hash lookup is O(1); avoids regex in a loop.
Readonly::Hash my %SOUNDING_EVENT_TYPES => map { $_ => 1 } qw(Note Rest Chord Bar);

=head1 NAME

Music::NWC2MusicXML::Staff - Internal representation of a single NWC staff.

=head1 VERSION

0.001.1

=head1 SYNOPSIS

    use Music::NWC2MusicXML::Staff;

    my $staff = Music::NWC2MusicXML::Staff->new(
        name       => 'Violin I',
        group      => 'Standard',
        instrument => { name => 'String Ensemble 1', patch => 48 },
    );

    $staff->add_event($note_event);
    my $events = $staff->events;

=head1 DESCRIPTION

C<Music::NWC2MusicXML::Staff> holds all information about one NWC staff: its
properties (name, visibility, number of lines), instrument data, and the
ordered sequence of C<Music::NWC2MusicXML::Event> objects that constitute its
musical content.

The event list is in parse order.  MusicXML generation iterates over it
to produce C<< <measure> >> elements.

=cut

sub new {
	my ($class, %input) = @_;
	my $args = validate_strict(
		schema => {
			name          => { type => 'scalar',  optional => 1, default  => 'Staff' },
			group         => { type => 'scalar',  optional => 1, default  => 'Standard' },
			lines         => { type => 'scalar',  optional => 1, default  => 5 },
			visible       => { type => 'scalar',  optional => 1, default  => 1 },
			ending_bar    => { type => 'scalar',  optional => 1 },
			instrument    => { type => 'hashref', optional => 1, default  => {} },
			initial_clef  => { type => 'scalar',  optional => 1 },
			initial_key   => { type => 'hashref', optional => 1 },
			initial_timesig => { type => 'hashref', optional => 1 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $self = bless {
		_name            => $args->{name},
		_group           => $args->{group},
		_lines           => $args->{lines},
		_visible         => $args->{visible},
		_ending_bar      => $args->{ending_bar},
		_instrument      => $args->{instrument},
		_initial_clef    => $args->{initial_clef},
		_initial_key     => $args->{initial_key},
		_initial_timesig => $args->{initial_timesig},
		_events          => [],
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

=head2 name

Return the staff name string.

=cut

sub name            { return $_[0]->{_name} }

=head2 group

Return the group name string.

=cut

sub group           { return $_[0]->{_group} }

=head2 lines

Return the number of staff lines (usually 5).

=cut

sub lines           { return $_[0]->{_lines} }

=head2 visible

Return 1 if the staff is visible, 0 otherwise.

=cut

sub visible         { return $_[0]->{_visible} }

=head2 instrument

Return the instrument information hashref.

Keys: C<name> (string), C<patch> (MIDI patch number 0-127).

=cut

sub instrument      { return $_[0]->{_instrument} }

=head2 initial_clef

Return the initial clef string (e.g. C<Treble>), or undef if none recorded.

=cut

sub initial_clef    { return $_[0]->{_initial_clef} }

=head2 set_initial_clef

Set the initial clef.

=cut

sub set_initial_clef {
	my ($self, $clef) = @_;
	$self->{_initial_clef} = $clef;
	return $self;
}

=head2 initial_key

Return the initial key hashref (C<signature>, C<tonic>, C<mode>), or undef.

=cut

sub initial_key     { return $_[0]->{_initial_key} }

=head2 set_initial_key

Set the initial key.

=cut

sub set_initial_key {
	my ($self, $key) = @_;
	$self->{_initial_key} = $key;
	return $self;
}

=head2 initial_timesig

Return the initial time-signature hashref (C<beats>, C<beat_type>), or undef.

=cut

sub initial_timesig { return $_[0]->{_initial_timesig} }

=head2 set_initial_timesig

Set the initial time signature.

=cut

sub set_initial_timesig {
	my ($self, $ts) = @_;
	$self->{_initial_timesig} = $ts;
	return $self;
}

# ---------------------------------------------------------------------------
# Event management
# ---------------------------------------------------------------------------

=head2 add_event

Append a C<Music::NWC2MusicXML::Event> to this staff's event list.

=head3 Purpose

Used by the parser to build the ordered event sequence as it processes NWCTXT
records belonging to this staff.

=head3 Arguments

=over 4

=item C<$event> -- a blessed C<Music::NWC2MusicXML::Event> object (required).

=back

=head3 Returns

C<$self> (for chaining).

=head3 Side Effects

Appends to C<_events> array.

=head3 Usage Example

    $staff->add_event(
        Music::NWC2MusicXML::Event->new(type => 'Note', ...)
    );

=head3 API SPECIFICATION

=head4 Input

    $event : Music::NWC2MusicXML::Event (required)

=head4 Output

    $self (Music::NWC2MusicXML::Staff)

=head3 MESSAGES

| Code           | Meaning                                | Resolution                      |
|----------------|----------------------------------------|---------------------------------|
| error_bad_event| Argument is not a Music::NWC2MusicXML::Event  | Construct event before adding   |

=head3 FORMAL SPECIFICATION

 [AddEvent]
   DeltaStaff
   event? : Event
   ---------
   events' = events ^ <event?>

 (placeholder)

=cut

sub add_event {
	my ($self, $event) = @_;
	croak _fmt_msg('error_bad_event', ref($event) // 'SCALAR')
		unless blessed($event) && $event->isa('Music::NWC2MusicXML::Event');
	push @{ $self->{_events} }, $event;
	return $self;
}

=head2 events

Return an arrayref of all C<Music::NWC2MusicXML::Event> objects in parse order.

=head3 Returns

Arrayref of C<Music::NWC2MusicXML::Event>.

=head3 API SPECIFICATION

=head4 Input

    (none)

=head4 Output

    ARRAYREF of Music::NWC2MusicXML::Event

=cut

sub events {
	my ($self) = @_;
	return $self->{_events};
}

=head2 musical_events

Return an arrayref containing only the events where C<is_musical_event> is
true.  Metadata records are excluded.

=cut

sub musical_events {
	my ($self) = @_;
	return [ grep { $_->is_musical_event } @{ $self->{_events} } ];
}

=head2 event_count

Return the total number of events (musical + metadata).

=cut

sub event_count {
	my ($self) = @_;
	return scalar @{ $self->{_events} };
}

=head2 has_notes

Return true if any note, rest, chord, or bar event has been added to this
staff.  Used by the parser to distinguish staff-header records (before any
sounding content) from mid-staff change records.

=cut

sub has_notes {
	my ($self) = @_;
	for my $ev (@{ $self->{_events} }) {
		return 1 if $SOUNDING_EVENT_TYPES{ $ev->type };
	}
	return 0;
}

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

sub _fmt_msg {
	my ($key, @args) = @_;
	croak "Unknown message key: $key" unless exists $MESSAGES{$key};
	return sprintf $MESSAGES{$key}, @args;
}

1;

__END__

=head1 DIAGNOSTICS

=head3 MESSAGES

| Code            | Meaning                   | Resolution                       |
|-----------------|---------------------------|----------------------------------|
| error_bad_event | Non-Event passed to add   | Construct a proper Event first   |

=head1 LIMITATIONS

=over 4

=item * Multi-voice detection (simultaneous events on different voices within one staff) is performed by the MusicXML generator, not by this class.

=item * The event list is unstructured; measure boundaries are deduced from Bar events during generation.

=back

=head1 AUTHOR

Nigel Horne C<< <nigel.horne@gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

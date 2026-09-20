package Music::NWC2MusicXML::Event;

use strict;
use warnings;

our $VERSION = '0.001.1';

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Params::Get;

# ---------------------------------------------------------------------------
# Valid event types (both musical events and score/staff metadata markers)
# ---------------------------------------------------------------------------
Readonly::Hash my %MUSICAL_EVENT_TYPES => map { $_ => 1 } qw(
	Note
	Rest
	Chord
	Clef
	Key
	TimeSig
	Tempo
	Dynamic
	DynVariance
	TempoVariance
	Text
	Lyric
	Bar
	Tie
	Slur
	Beam
	Tuplet
	Instrument
	FlowControl
	UnsupportedEvent
);

Readonly::Hash my %METADATA_EVENT_TYPES => map { $_ => 1 } qw(
	SongInfo
	PgSetup
	AddStaff
	StaffProperties
	StaffInstrument
);

# ---------------------------------------------------------------------------
# Duration map: NWC duration name -> rational denominator (quarter = 1/1)
# Using [numerator, denominator] pairs where the base unit is one quarter note.
# ---------------------------------------------------------------------------
Readonly::Hash my %DURATION_RATIONALS => (
	'Whole'          => [ 4, 1 ],
	'Half'           => [ 2, 1 ],
	'4th'            => [ 1, 1 ],
	'8th'            => [ 1, 2 ],
	'16th'           => [ 1, 4 ],
	'32nd'           => [ 1, 8 ],
	'64th'           => [ 1, 16 ],
);

# Dotted note: multiply by 3/2; double-dotted: 7/4
Readonly::Scalar my $DOT_NUMERATOR   => 3;
Readonly::Scalar my $DOT_DENOMINATOR => 2;

Readonly::Hash my %MESSAGES => (
	error_unknown_type      => 'Unknown event type: %s',
	error_bad_duration      => 'Unrecognised NWC duration: %s',
	error_bad_rational      => 'Rational arguments must be positive integers',
	error_internal          => 'Internal error: %s',
);

=head1 NAME

Music::NWC2MusicXML::Event - Internal representation of a single NWC musical event
or score metadata record.

=head1 VERSION

0.001.1

=head1 SYNOPSIS

    use Music::NWC2MusicXML::Event;

    # Musical event
    my $note = Music::NWC2MusicXML::Event->new(
        type       => 'Note',
        start_time => [0, 1],   # rational: 0 quarter-notes from measure start
        duration   => [1, 1],   # rational: one quarter note
        data       => {
            pitch      => 'C',
            octave     => 4,
            accidental => 0,
        },
    );

    # Unsupported / unknown object
    my $unknown = Music::NWC2MusicXML::Event->new(
        type      => 'UnsupportedEvent',
        nwc_label => 'SomeFutureObject',
        data      => { raw => '|SomeFutureObject|...' },
    );

=head1 DESCRIPTION

C<Music::NWC2MusicXML::Event> is the internal representation of one NWC record.
It covers both musical events (notes, rests, bars, dynamics, ...) and
score/staff metadata (SongInfo, StaffProperties, ...).

Musical timing is represented using exact rational numbers stored as
two-element arrayrefs C<[$numerator, $denominator]>.  Floating-point
arithmetic is never used for musical durations; this avoids cumulative
rounding errors when dividing a beat into complex tuplet groupings.

Unknown NWC object types are stored as C<UnsupportedEvent> records so
that conversion can continue rather than aborting.

=cut

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

=head2 new

Construct a new Event.

=head3 Purpose

Factory constructor used by the parser to wrap each parsed NWC record into a
typed, time-stamped object suitable for later MusicXML generation.

=head3 Arguments

Named parameters:

=over 4

=item C<type> (string, required) -- one of the recognised event type names
listed in C<%MUSICAL_EVENT_TYPES> or C<%METADATA_EVENT_TYPES>, or
C<UnsupportedEvent>.

=item C<nwc_label> (string, optional) -- the original NWC record label, useful
when C<type> is C<UnsupportedEvent>.

=item C<start_time> (arrayref [$num,$den], optional) -- rational offset from
the beginning of the current measure.  Default C<[0,1]>.

=item C<duration> (arrayref [$num,$den], optional) -- rational duration in
quarter-note units.  Default C<[0,1]> for non-durational events.

=item C<data> (hashref, optional) -- type-specific payload (see below).

=back

=head3 Data payloads by type

=over 4

=item B<Note> -- C<pitch>, C<octave>, C<accidental>, C<tie_start>, C<tie_stop>,
C<slur_start>, C<slur_stop>, C<articulations> (arrayref), C<stem_direction>,
C<grace>.

=item B<Rest> -- (no pitch fields).

=item B<Chord> -- C<notes> (arrayref of Note-like hashrefs).

=item B<Clef> -- C<nwc_clef> (e.g. C<Treble>).

=item B<Key> -- C<nwc_signature> (e.g. C<Bb>), C<tonic>, C<mode>.

=item B<TimeSig> -- C<beats>, C<beat_type>.

=item B<Tempo> -- C<bpm>.

=item B<Dynamic> -- C<marking> (e.g. C<mf>).

=item B<Lyric> -- C<text>, C<verse>, C<syllabic> (C<begin>|C<middle>|C<end>|C<single>).

=item B<Bar> -- C<style> (C<normal>|C<double>|C<final>|C<repeat_start>|C<repeat_end>|C<section>).

=item B<FlowControl> -- C<directive> (e.g. C<Coda>, C<Segno>, C<DaCapo>).

=item B<UnsupportedEvent> -- C<raw> (original NWC text line).

=back

=head3 Returns

A blessed C<Music::NWC2MusicXML::Event> object.

=head3 Side Effects

None.

=head3 Usage Example

    my $rest = Music::NWC2MusicXML::Event->new(
        type       => 'Rest',
        start_time => [1, 1],
        duration   => [1, 2],   # eighth rest
    );

=head3 API SPECIFICATION

=head4 Input

    type       : SCALAR  (required)
                   -- Valid domain: any string registered in %MUSICAL_EVENT_TYPES
                   --   or %METADATA_EVENT_TYPES (see Event.pm constants)
                   -- Invalid partition: unknown/unregistered string, undef, or ''
                   --   -> stored as UnsupportedEvent (carp), not croak
    nwc_label  : SCALAR  (optional)
    start_time : ARRAYREF [int>=0, int>0]  (optional, default [0,1])
                   -- Valid domain: exactly-2-element arrayref [numerator, denominator]
                   --   where denominator > 0.  Numerator >= 0.
                   -- Invalid: non-arrayref, 1-element, 3+-element, or denominator=0
                   --   -> croak error_bad_rational
    duration   : ARRAYREF [int>=0, int>0]  (optional, default [0,1])
                   -- Same constraints as start_time
    data       : HASHREF  (optional, default {})

=head4 Output

    Music::NWC2MusicXML::Event object

=head3 MESSAGES

| Code                | Meaning                                 | Resolution             |
|---------------------|-----------------------------------------|------------------------|
| error_unknown_type  | Type string not in recognised set       | Check NWC record label |
| error_bad_rational  | start_time or duration malformed        | Use [$num,$den] form   |

=head3 FORMAL SPECIFICATION

 [EventInit]
   type       : EventType
   start_time : Q+  (non-negative rational)
   duration   : Q+  (non-negative rational)
   data       : DATA

 (placeholder -- populate with Z calculus as implementation matures)

=cut

sub new {
	my ($class, %input) = @_;
	my $args = validate_strict(
		schema => {
			type       => { type => 'scalar' },
			nwc_label  => { type => 'scalar',   optional => 1 },
			start_time => { type => 'arrayref', optional => 1, default  => [0, 1] },
			duration   => { type => 'arrayref', optional => 1, default  => [0, 1] },
			data       => { type => 'hashref',  optional => 1, default  => {} },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	# Normalise unknown types to UnsupportedEvent rather than croaking;
	# this preserves conversion continuity when new NWC versions add objects.
	my $type_key = $args->{type} // '';
	unless (
		exists $MUSICAL_EVENT_TYPES{$type_key}
		|| exists $METADATA_EVENT_TYPES{$type_key}
	) {
		carp _fmt_msg('error_unknown_type', $type_key || '(undef)')
			. ' -- storing as UnsupportedEvent';
		$args->{nwc_label} //= $args->{type};
		$args->{type} = 'UnsupportedEvent';
	}

	_validate_rational($args->{start_time});
	_validate_rational($args->{duration});

	my $self = bless {
		_type       => $args->{type},
		_nwc_label  => $args->{nwc_label} // $args->{type},
		_start_time => _reduce_rational($args->{start_time}),
		_duration   => _reduce_rational($args->{duration}),
		_data       => $args->{data},
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

=head2 type

Return the event type string.

=head3 Returns

Scalar string.

=cut

sub type       { return $_[0]->{_type} }

=head2 nwc_label

Return the original NWC record label (especially useful for UnsupportedEvent).

=cut

sub nwc_label  { return $_[0]->{_nwc_label} }

=head2 start_time

Return the rational start time as an arrayref C<[$num, $den]>.

=cut

sub start_time { return $_[0]->{_start_time} }

=head2 duration

Return the rational duration as an arrayref C<[$num, $den]>.

=cut

sub duration   { return $_[0]->{_duration} }

=head2 data

Return the type-specific payload hashref.

=cut

sub data       { return $_[0]->{_data} }

=head2 is_musical_event

Return true if this event contributes to the musical timeline (note, rest,
chord, ...) as opposed to being a metadata record.

=cut

sub is_musical_event {
	my ($self) = @_;
	return exists $MUSICAL_EVENT_TYPES{ $self->{_type} };
}

=head2 is_metadata

Return true if this record is score/staff metadata.

=cut

sub is_metadata {
	my ($self) = @_;
	return exists $METADATA_EVENT_TYPES{ $self->{_type} };
}

# ---------------------------------------------------------------------------
# Rational arithmetic helpers (class-level, not methods)
# ---------------------------------------------------------------------------

=head2 rational_from_nwc_duration

Class method.  Convert an NWC duration name and dot count to a rational
arrayref C<[$num, $den]> in quarter-note units.

=head3 Arguments

=over 4

=item C<nwc_duration> -- string such as C<4th>, C<8th>, C<Half> etc.

=item C<dots>         -- number of augmentation dots (0, 1, or 2).

=back

=head3 Returns

Arrayref C<[$num, $den]>.

=head3 API SPECIFICATION

=head4 Input

    nwc_duration : SCALAR (required)
                     -- Valid domain: exactly one of the 7 NWC duration names:
                     --   'Whole', 'Half', '4th', '8th', '16th', '32nd', '64th'
                     -- Invalid partitions: undef, '' (empty), 'Quarter' (wrong name),
                     --   'whole' (wrong case), any other string -> croak error_bad_duration
                     -- Note: NWC uses '4th' not 'Quarter' for the quarter note.
    dots         : SCALAR int >= 0 (optional, default 0)
                     -- Valid domain: 0 (no dots), 1 (dotted), 2 (double-dotted)
                     -- NWC maximum is 2; dots=3+ are mathematically valid but not
                     --   produced by any NWC 2.x score; undef treated as 0

=head4 Output

    ARRAYREF [$num:int, $den:int]  (rational in quarter-note units, reduced to lowest terms)

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub rational_from_nwc_duration {
	my $class        = shift;
	my ($dur, $dots) = @_;
	$dots //= 0;

	croak _fmt_msg('error_bad_duration', $dur // '(undef)')
		unless defined $dur && exists $DURATION_RATIONALS{$dur};

	my $r      = $DURATION_RATIONALS{$dur};
	# P: table values are already in lowest terms; _reduce_rational is a no-op for dots=0.
	return $r unless $dots;

	my $base_r = $r;   # preserve original: dot d adds base/2^d, not cur/2^d

	for my $d (1 .. $dots) {
		my $add_num = $base_r->[0];
		my $add_den = $base_r->[1] * (2 ** $d);
		$r = _add_rationals($r, [$add_num, $add_den]);
	}

	return _reduce_rational($r);
}

=head2 rational_add

Class method.  Add two rational numbers.

=head3 Arguments

Two arrayrefs C<[$n1,$d1]> and C<[$n2,$d2]>.

=head3 Returns

Arrayref C<[$num,$den]> in lowest terms.

=cut

sub rational_add {
	my ($class, $r1, $r2) = @_;
	return _reduce_rational(_add_rationals($r1, $r2));
}

=head2 rational_to_float

Class method.  Convert a rational to a floating-point number for display
or approximate comparison only.  Never use the result for musical timing.

=head3 API SPECIFICATION

=head4 Input

    $r : ARRAYREF [$num:int, $den:int>0]  (required)
           -- Valid domain: exactly-2-element arrayref where $den > 0
           -- Invalid: non-arrayref scalar, 1-element arrayref, 3+-element arrayref,
           --   or denominator = 0 -> croak error_bad_rational
           -- BVA boundary: $num = 0 is valid (returns 0.0)

=head4 Output

    SCALAR (floating-point approximation of $num / $den)

=cut

sub rational_to_float {
	my ($class, $r) = @_;
	croak _fmt_msg('error_bad_rational') unless ref $r eq 'ARRAY' && @$r == 2 && $r->[1];
	return $r->[0] / $r->[1];
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _validate_rational {
	my ($r) = @_;
	croak _fmt_msg('error_bad_rational')
		unless ref $r eq 'ARRAY'
		&& @$r == 2
		&& $r->[0] =~ /\A\d+\z/
		&& $r->[1] =~ /\A[1-9]\d*\z/;
	return;
}

sub _add_rationals {
	my ($r1, $r2) = @_;
	my $num = $r1->[0] * $r2->[1] + $r2->[0] * $r1->[1];
	my $den = $r1->[1] * $r2->[1];
	return [$num, $den];
}

sub _reduce_rational {
	my ($r) = @_;
	my $g = _gcd($r->[0], $r->[1]);
	return $g ? [$r->[0] / $g, $r->[1] / $g] : [0, 1];
}

sub _gcd {
	my ($a, $b) = @_;
	($a, $b) = ($b, $a % $b) while $b;
	return $a;
}

sub _fmt_msg {
	my ($key, @args) = @_;
	croak "Unknown message key: $key" unless exists $MESSAGES{$key};
	return sprintf $MESSAGES{$key}, @args;
}

1;

__END__

=head1 DIAGNOSTICS

=head3 MESSAGES

| Code                 | Meaning                              | Resolution                  |
|----------------------|--------------------------------------|-----------------------------|
| error_unknown_type   | Unrecognised event type              | Will be stored as UnsupportedEvent |
| error_bad_duration   | NWC duration name not in lookup table| Check parser input          |
| error_bad_rational   | Rational arrayref malformed          | Use [$non-neg-int, $pos-int] |

=head1 LIMITATIONS

=over 4

=item * Double-dotted notes supported; triple-dotted are not.

=item * Tuplet time-modification is not computed here; the parser applies it to each affected event.

=back

=head1 AUTHOR

Nigel Horne C<< <nigel.horne@gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

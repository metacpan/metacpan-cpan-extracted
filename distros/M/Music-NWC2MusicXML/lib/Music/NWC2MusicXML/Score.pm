package Music::NWC2MusicXML::Score;

use strict;
use warnings;

our $VERSION = '0.002.0';

use Carp qw(croak carp);
use List::Util qw(any);
use Readonly;
use Scalar::Util qw(blessed);
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Music::NWC2MusicXML::Staff;

Readonly::Hash my %MESSAGES => (
	error_bad_staff       => 'add_staff: argument must be a Music::NWC2MusicXML::Staff, got: %s',
	error_no_staves       => 'Score contains no staves',
	error_internal        => 'Internal error: %s',
	warn_empty_staff      => "Staff '%s' has no events",
	warn_bar_duration     => "Staff '%s', measure %d: duration %s quarter-notes does not match time signature (%s expected)",
	warn_unmatched_tie    => "Staff '%s': unterminated tie from position '%s'",
	warn_unclosed_slur    => "Staff '%s': slur arc not closed at end of staff",
);

# Recognised SongInfo keys that map to MusicXML metadata elements
Readonly::Array my @SONGINFO_KEYS => qw(
	Title
	Author
	Lyricist
	Copyright
	Copyright1
	Copyright2
	Comments
);

=head1 NAME

Music::NWC2MusicXML::Score - Internal representation of a complete NWC score.

=head1 VERSION

0.002.0

=head1 SYNOPSIS

    use Music::NWC2MusicXML::Score;

    my $score = Music::NWC2MusicXML::Score->new(
        metadata   => { Title => 'To a Pilgrim', Author => 'Trad, Arr Nigel Horne' },
        page_setup => { StaffSize => 16, Zoom => 3 },
    );

    $score->add_staff($staff_object);
    my $staves = $score->staves;

=head1 DESCRIPTION

C<Music::NWC2MusicXML::Score> is the root of the internal representation tree.
It holds:

=over 4

=item * B<metadata> -- SongInfo fields (Title, Author, Lyricist, Copyright, Comments).

=item * B<page_setup> -- PgSetup fields, retained but largely informational.

=item * B<properties> -- additional score-level NWC properties.

=item * B<staves> -- ordered list of C<Music::NWC2MusicXML::Staff> objects.

=back

This class is MusicXML-agnostic; it describes the musical content in NWC
terms.  The C<Music::NWC2MusicXML::MusicXML> generator translates it to XML.

=cut

sub new {
	my ($class, %input) = @_;
	my $args = validate_strict(
		schema => {
			metadata      => { type => 'hashref', optional => 1, default  => {} },
			page_setup    => { type => 'hashref', optional => 1, default  => {} },
			properties    => { type => 'hashref', optional => 1, default  => {} },
			nwc_version   => { type => 'scalar',  optional => 1 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $self = bless {
		_metadata    => $args->{metadata},
		_page_setup  => $args->{page_setup},
		_properties  => $args->{properties},
		_nwc_version => $args->{nwc_version},
		_staves      => [],
		_fonts       => [],
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

=head2 metadata

Return the metadata hashref.

Keys correspond to NWC SongInfo field names: C<Title>, C<Author>,
C<Lyricist>, C<Copyright>, C<Comments>.

=head3 Returns

Hashref.

=cut

sub metadata    { return $_[0]->{_metadata} }

=head2 page_setup

Return the page-setup hashref (NWC PgSetup fields).

=cut

sub page_setup  { return $_[0]->{_page_setup} }

=head2 properties

Return additional score-level properties hashref.

=cut

sub properties  { return $_[0]->{_properties} }

=head2 nwc_version

Return the NWC version string extracted from the NWCTXT header
(e.g. C<2.751>), or undef if not available.

=cut

sub nwc_version { return $_[0]->{_nwc_version} }

=head2 fonts

Return the arrayref of font descriptors parsed from NWC Font records.
Each entry is a hashref with keys: style, typeface, size, bold, italic.

=cut

sub fonts { return $_[0]->{_fonts} }

=head2 set_metadata_field

Set a single metadata field.

=head3 Arguments

=over 4

=item C<$key>   -- field name (e.g. C<Title>).

=item C<$value> -- string value.

=back

=head3 Returns

C<$self>.

=cut

sub set_metadata_field {
	my ($self, $key, $value) = @_;
	$self->{_metadata}{$key} = $value;
	return $self;
}

# ---------------------------------------------------------------------------
# Staff management
# ---------------------------------------------------------------------------

=head2 add_staff

Append a C<Music::NWC2MusicXML::Staff> to the score's staff list.

=head3 Purpose

Called by the parser each time it encounters an C<AddStaff> record; the staff
object is populated with subsequent per-staff records and then stays in the
list for MusicXML generation.

=head3 Arguments

=over 4

=item C<$staff> -- a blessed C<Music::NWC2MusicXML::Staff> object (required).

=back

=head3 Returns

C<$self> (for chaining).

=head3 Side Effects

Appends to C<_staves>.

=head3 Usage Example

    $score->add_staff(
        Music::NWC2MusicXML::Staff->new(name => 'Violin I')
    );

=head3 API SPECIFICATION

=head4 Input

    $staff : Music::NWC2MusicXML::Staff (required)

=head4 Output

    $self (Music::NWC2MusicXML::Score)

=head3 MESSAGES

| Code           | Meaning                          | Resolution                   |
|----------------|----------------------------------|------------------------------|
| error_bad_staff| Argument is not a Staff object   | Construct Staff before adding |

=head3 FORMAL SPECIFICATION

 [AddStaff]
   DeltaScore
   staff? : Staff
   ---------
   staves' = staves ^ <staff?>

 (placeholder -- populate with Z calculus as implementation matures)

=cut

sub add_staff {
	my ($self, $staff) = @_;
	croak _fmt_msg('error_bad_staff', ref($staff) // 'SCALAR')
		unless blessed($staff) && $staff->isa('Music::NWC2MusicXML::Staff');
	push @{ $self->{_staves} }, $staff;
	return $self;
}

=head2 staves

Return an arrayref of all C<Music::NWC2MusicXML::Staff> objects in score order.

=head3 Returns

Arrayref of C<Music::NWC2MusicXML::Staff>.

=head3 API SPECIFICATION

=head4 Input

    (none)

=head4 Output

    ARRAYREF of Music::NWC2MusicXML::Staff

=cut

sub staves {
	my ($self) = @_;
	return $self->{_staves};
}

=head2 current_staff

Return the last staff appended (the one currently being populated by the
parser), or undef if no staves have been added.

=cut

sub current_staff {
	my ($self) = @_;
	return $self->{_staves}[-1];
}

=head2 staff_count

Return the number of staves.

=cut

sub staff_count {
	my ($self) = @_;
	return scalar @{ $self->{_staves} };
}

=head2 validate

Perform consistency checks on the score structure.  Called when
C<--validate> is passed on the command line.

=head3 Purpose

Checks that every staff has at least one event, that tie/slur relationships
are consistent, and that measure durations match the current time signature.

=head3 Returns

Arrayref of diagnostic strings (empty on success).

=head3 API SPECIFICATION

=head4 Input

    (none)

=head4 Output

    ARRAYREF of SCALAR (diagnostic messages)

=head3 FORMAL SPECIFICATION

 [Validate]
   score : Score
   ---------
   forall s : staves @ valid_staff(s)

 (placeholder)

=cut

sub validate {
	my $self = $_[0];

	# Strategy: iterate staves; for each staff check that:
	#  - event list is non-empty
	#  - all Bar events divide time correctly per time signature
	#  - all Tie/Slur events have matching start/stop pairs
	# Return all accumulated diagnostics rather than croaking on first failure.

	my @diagnostics;

	if ($self->staff_count == 0) {
		push @diagnostics, _fmt_msg('error_no_staves');
		return \@diagnostics;
	}

	for my $staff (@{ $self->{_staves} }) {
		my $sname = $staff->name // '(unnamed)';

		if ($staff->event_count == 0) {
			push @diagnostics, _fmt_msg('warn_empty_staff', $sname);
			next;
		}

		my %pending_tie;          # pos_key => 1  for ties awaiting a stop
		my $in_slur    = 0;       # 1 while inside an unclosed slur arc
		my $bar_num    = 1;
		my ($acc_n, $acc_d) = (0, 1);   # accumulated bar duration as a rational

		my $ts = $staff->initial_timesig // {};
		my ($exp_n, $exp_d) = _ts_to_rational($ts);

		for my $ev (@{ $staff->events }) {
			my $type = $ev->type;
			my $d    = $ev->data // {};

			if ($type eq 'TimeSig') {
				($exp_n, $exp_d) = _ts_to_rational($d);
				next;
			}

			if ($type eq 'Bar') {
				if ($acc_n > 0 && $exp_n > 0) {
					my ($cn, $cd) = _rat_reduce($acc_n, $acc_d);
					my ($en, $ed) = _rat_reduce($exp_n, $exp_d);
					push @diagnostics, _fmt_msg(
						'warn_bar_duration', $sname, $bar_num,
						"$cn/$cd", "$en/$ed",
					) unless $cn * $ed == $en * $cd;
				}
				$bar_num++;
				($acc_n, $acc_d) = (0, 1);
				next;
			}

			next unless $type eq 'Note' || $type eq 'Chord' || $type eq 'Rest';

			# Accumulate duration (grace notes contribute nothing)
			unless ($d->{is_grace}) {
				my ($dn, $dd) = @{ $d->{duration} // [0, 1] };
				($acc_n, $acc_d) = _rat_reduce(
					$acc_n * $dd + $dn * $acc_d,
					$acc_d * $dd,
				);
			}

			# Tie tracking (rests cannot be tied)
			unless ($type eq 'Rest') {
				my @pos_strs = $type eq 'Chord'
					? @{ $d->{nwc_positions} // [] }
					: ($d->{nwc_pos} // '0');
				for my $ps (@pos_strs) {
					(my $pk = $ps) =~ s/\^\z//;
					delete $pending_tie{$pk};          # consume any pending stop
					$pending_tie{$pk} = 1 if $ps =~ /\^\z/;
				}
			}

			# Slur tracking (rests are transparent to slur arcs)
			next if $type eq 'Rest';
			$in_slur = any { $_ eq 'Slur' } @{ $d->{articulations} // [] } ? 1 : 0;
		}

		for my $pk (sort keys %pending_tie) {
			push @diagnostics, _fmt_msg('warn_unmatched_tie', $sname, $pk);
		}
		push @diagnostics, _fmt_msg('warn_unclosed_slur', $sname) if $in_slur;
	}

	return \@diagnostics;
}

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

sub _fmt_msg {
	my ($key, @args) = @_;
	croak "Unknown message key: $key" unless exists $MESSAGES{$key};
	return sprintf $MESSAGES{$key}, @args;
}

# Convert a timesig hashref {beats, beat_type} to a rational [n, d] in quarter-note units.
# Returns (0, 1) when the timesig is absent or incomplete.
sub _ts_to_rational {
	my ($ts) = @_;
	return (0, 1) unless ref $ts eq 'HASH' && $ts->{beats} && $ts->{beat_type};
	return _rat_reduce($ts->{beats} * 4, $ts->{beat_type});
}

# Reduce a fraction to lowest terms.  Returns ($n, $d) with $d > 0.
sub _rat_reduce {
	my ($n, $d) = @_;
	return (0, 1) unless $n;
	my $g = _gcd(abs($n), abs($d));
	return ($n / $g, $d / $g);
}

sub _gcd {
	my ($a, $b) = @_;
	($a, $b) = ($b, $a % $b) while $b;
	return $a;
}

1;

__END__

=head1 DIAGNOSTICS

=head3 MESSAGES

| Code            | Meaning                  | Resolution                         |
|-----------------|--------------------------|------------------------------------|
| error_bad_staff | Non-Staff passed to add  | Construct a proper Staff first     |
| error_no_staves | Score has no staves      | Ensure NWCTXT contains AddStaff    |

=head1 LIMITATIONS

=over 4

=item * Page-layout and graphical properties are stored but not used in MusicXML generation.

=back

=head1 AUTHOR

Nigel Horne C<< <nigel.horne@gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

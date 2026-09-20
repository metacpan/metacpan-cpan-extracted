package Music::NWC2MusicXML::Parser;

use strict;
use warnings;
use autodie qw(:all);

our $VERSION = '0.001.1';

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Maximum number of records to parse before deciding the file is pathological.
Readonly::Scalar my $MAX_RECORDS => 1_000_000;

# The NWCTXT header line prefix
Readonly::Scalar my $HEADER_PREFIX => '!NoteWorthyComposer(';

# Dynamic markings recognised by NWC
Readonly::Hash my %VALID_DYNAMICS => map { $_ => 1 }
	qw(pppp ppp pp p mp mf f ff fff ffff);

# Clef names recognised by NWC and their canonical spellings
Readonly::Hash my %VALID_CLEFS => map { $_ => 1 }
	qw(Treble Bass Alto Tenor Percussion Tab);

# NWC lists key-signature accidentals in the standard circle-of-fifths order.
# Signature:F#,C#  = 2 sharps = D major  (fifths +2)
# Signature:Bb     = 1 flat   = F major  (fifths -1)
# We compute the fifths value by counting the accidentals rather than using
# a lookup table, which handles any combination and avoids the common mistake
# of confusing the tonic name with the signature accidental list.

# The 'C' signature token means no accidentals (C major / A minor = fifths 0).
Readonly::Scalar my $KEY_SIG_NATURAL => 'C';

# Pitch step letters recognised in NWC note records
Readonly::Hash my %VALID_STEPS => map { $_ => 1 } qw(A B C D E F G);

Readonly::Hash my %MESSAGES => (
	error_empty_input     => 'NWCTXT input is empty or undefined',
	error_no_header       => 'NWCTXT does not begin with expected header',
	error_too_many_records=> 'Input exceeds maximum record limit (%d)',
	error_bad_record      => 'Malformed NWCTXT record at line %d: %s',
	error_no_staff        => 'Musical event %s encountered before any AddStaff record',
	error_internal        => 'Internal error: %s',
	warn_unknown_record   => 'Unknown NWCTXT record type %s at line %d -- stored as UnsupportedEvent',
	warn_bad_value        => 'Unrecognised value for %s: %s at line %d',
);

=head1 NAME

Music::NWC2MusicXML::Parser - NWCTXT text parser producing an internal score
representation.

=head1 VERSION

0.001.1

=head1 SYNOPSIS

    use Music::NWC2MusicXML::Parser;

    my $parser = Music::NWC2MusicXML::Parser->new;
    my $score  = $parser->parse($nwctxt);

=head1 DESCRIPTION

C<Music::NWC2MusicXML::Parser> accepts the NWCTXT string produced by
C<Music::NWC2MusicXML::NWC> and returns a C<Music::NWC2MusicXML::Score> object.

The internal representation is completely independent of MusicXML so that
parsing and MusicXML generation can be tested separately.

=head2 NWCTXT record structure

Each record occupies one line and begins with C<|>:

    |RecordType|Field1:Value1|Field2:Value2|...

Fields are pipe-delimited.  Values may be:

=over 4

=item * unquoted single tokens

=item * double-quoted strings (which may contain C<|> and C<:>)

=item * comma-separated lists

=back

The parser does B<not> use C<split(/[|]/)> because quoted values and escape
sequences require a proper tokeniser.

=cut

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

=head2 new

Construct a parser.

=head3 Arguments

Named parameters:

=over 4

=item C<diagnostics> -- a C<Music::NWC2MusicXML::Diagnostics> instance (optional).

=back

=head3 Returns

Blessed C<Music::NWC2MusicXML::Parser> object.

=head3 API SPECIFICATION

=head4 Input

    diagnostics : Music::NWC2MusicXML::Diagnostics  (optional)

=head4 Output

    Music::NWC2MusicXML::Parser object

=head3 FORMAL SPECIFICATION

 [ParserInit]
   diagnostics : Diagnostics

 (placeholder -- populate with Z calculus as implementation matures)

=cut

sub new {
	my ($class, %input) = @_;
	my $args = validate_strict(
		schema => {
			diagnostics => { type => 'object', optional => 1 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $self = bless {
		_diagnostics => $args->{diagnostics},
		_score       => undef,
		_line_no     => 0,
		_record_count => 0,
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Public: parse
# ---------------------------------------------------------------------------

=head2 parse

Parse a complete NWCTXT string and return the corresponding
C<Music::NWC2MusicXML::Score>.

=head3 Purpose

This is the primary entry point.  It iterates over each line of the NWCTXT,
dispatches to a type-specific handler, and accumulates the results into a
Score object.

=head3 Arguments

=over 4

=item C<$nwctxt> -- scalar string containing the full NWCTXT representation
(required).

=back

=head3 Returns

A C<Music::NWC2MusicXML::Score> object.

=head3 Side Effects

Croaks on fatal structural errors (e.g. missing header).
Issues warnings via C<diagnostics> for non-fatal issues (e.g. unknown records).

=head3 Usage Example

    my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);

=head3 API SPECIFICATION

=head4 Input

    $nwctxt : SCALAR (UTF-8, required)
                -- Valid domain: non-empty string beginning with the line
                --   '!NoteWorthyComposer(<version>)' followed by pipe-delimited records
                -- Invalid partitions:
                --   undef or '' -> croaks error_empty_input
                --   non-empty but missing header -> croaks error_no_header
                -- Boundary: MAX_RECORDS = 1,000,000 pipe-delimited records
                --   At exactly 1,000,000 records: accepted
                --   At 1,000,001+ records: croaks error_too_many_records

=head4 Output

    Music::NWC2MusicXML::Score

=head3 MESSAGES

| Code                  | Meaning                                  | Resolution                    |
|-----------------------|------------------------------------------|-------------------------------|
| error_empty_input     | Input is undef or zero-length            | Check NWC decoder output      |
| error_no_header       | Header line not found                    | Verify NWC binary decoder     |
| error_too_many_records| Record count exceeds MAX_RECORDS         | Input may be malicious/corrupt|
| error_bad_record      | Record cannot be tokenised               | File may be corrupt           |
| error_no_staff        | Event seen before first AddStaff         | NWCTXT may be truncated       |
| warn_unknown_record   | Unknown record type stored as Unsupported| New NWC version may add types |

=head3 FORMAL SPECIFICATION

 [Parse]
   nwctxt? : NWCTXT
   ----------
   score!  : Score

 (placeholder)

=cut

sub parse {
	my ($self, $nwctxt) = @_;

	croak _fmt_msg('error_empty_input')
		unless defined $nwctxt && length $nwctxt;

	# Initialise fresh parse state for each call, enabling object reuse.
	$self->{_score}        = Music::NWC2MusicXML::Score->new;
	$self->{_line_no}      = 0;
	$self->{_record_count} = 0;

	my @lines = split /\r?\n/, $nwctxt;

	# First non-blank line must be the NWCTXT header
	my $header = shift @lines;
	$self->{_line_no}++;

	croak _fmt_msg('error_no_header')
		unless defined $header
		&& index($header, $HEADER_PREFIX) == 0;

	# Extract version string from header: !NoteWorthyComposer(2.751)
	my ($version) = $header =~ /\A\Q$HEADER_PREFIX\E([^)]+)/;
	$self->{_score}{_nwc_version} = $version;

	# Main parsing loop
	for my $line (@lines) {
		$self->{_line_no}++;
		next unless defined $line && length $line;
		next if $line =~ /\A\s*\z/;    # blank lines are legal

		croak _fmt_msg('error_too_many_records', $MAX_RECORDS)
			if ++$self->{_record_count} > $MAX_RECORDS;

		# All NWCTXT records begin with '|'
		next unless $line =~ /\A\|/;

		$self->_dispatch_record($line);
	}

	return $self->{_score};
}

# ---------------------------------------------------------------------------
# Package-level dispatch table -- built once at module load, not per call.
# Subs are compile-time symbols; Readonly ensures the table is never mutated.
# ---------------------------------------------------------------------------
Readonly::Hash my %DISPATCH => (
	SongInfo        => \&_handle_song_info,
	PgSetup         => \&_handle_pg_setup,
	PgMargins       => \&_handle_pg_setup,
	Font            => \&_handle_font,
	AddStaff        => \&_handle_add_staff,
	StaffProperties => \&_handle_staff_properties,
	StaffInstrument => \&_handle_staff_instrument,
	Clef            => \&_handle_clef,
	Key             => \&_handle_key,
	TimeSig         => \&_handle_time_sig,
	Tempo           => \&_handle_tempo,
	Note            => \&_handle_note,
	Rest            => \&_handle_rest,
	Chord           => \&_handle_chord,
	Bar             => \&_handle_bar,
	Dynamic         => \&_handle_dynamic,
	DynVariance     => \&_handle_dyn_variance,
	Text            => \&_handle_text,
	Lyric           => \&_handle_lyric,
	Tie             => \&_handle_tie,
	Slur            => \&_handle_slur,
	Beam            => \&_handle_beam,
	Tuplet          => \&_handle_tuplet,
	Instrument      => \&_handle_instrument_change,
	FlowControl     => \&_handle_flow_control,
	TempoVariance   => \&_handle_tempo_variance,
	Spacer          => \&_handle_spacer,
	RestChord       => \&_handle_rest_chord,
);

# ---------------------------------------------------------------------------
# Private: record dispatcher
# ---------------------------------------------------------------------------

# Strategy: extract the record type (first field after the leading |), then
# call a dedicated _handle_* method.  Unknown types produce UnsupportedEvent
# records and a warning rather than aborting conversion.

sub _dispatch_record {
	my ($self, $line) = @_;

	my $fields = $self->_tokenise_record($line);
	return unless defined $fields && @$fields;

	my $type = shift @$fields;

	if (exists $DISPATCH{$type}) {
		$DISPATCH{$type}->($self, $fields);
	} else {
		my $staff = $self->{_score}->current_staff;
		if (defined $staff) {
			# Unknown type within a staff: record and warn.
			$self->_warn_unknown($type);
			$self->_append_event(Music::NWC2MusicXML::Event->new(
				type      => 'UnsupportedEvent',
				nwc_label => $type,
				data      => { raw => join('|', $type, @$fields) },
			));
		}
		# else: score-level record (Editor, Font, PgMargins, ...) before any
		# AddStaff -- silently skip; these are not musical events.
	}
}

# ---------------------------------------------------------------------------
# Private: tokeniser
# ---------------------------------------------------------------------------

# Strategy: walk character by character to handle quoted strings and escaped
# characters correctly.  A naive split('|') would break on quoted values
# that contain '|' or ':'.

sub _tokenise_record {
	my ($self, $line) = @_;

	my @fields;
	my $pos = 0;
	my $len = length $line;

	# Skip leading '|'
	$pos++ if substr($line, 0, 1) eq '|';

	my $current = '';
	my $in_quote = 0;

	while ($pos < $len) {
		my $ch = substr($line, $pos, 1);

		if ($in_quote) {
			if ($ch eq '"') {
				$in_quote = 0;
			} elsif ($ch eq '\\' && $pos + 1 < $len) {
				# Escape sequence: consume next char literally
				$pos++;
				$current .= substr($line, $pos, 1);
			} else {
				$current .= $ch;
			}
		} else {
			if ($ch eq '"') {
				$in_quote = 1;
			} elsif ($ch eq '|') {
				push @fields, $current;
				$current = '';
			} else {
				$current .= $ch;
			}
		}
		$pos++;
	}

	push @fields, $current;

	return \@fields;
}

# Parse a field list (already tokenised) into a key => value hashref.
# Fields have the form "Key:Value" or just "Value" for positional fields.
sub _fields_to_hash {
	my ($self, $fields_ref) = @_;
	my %h;
	for my $field (@$fields_ref) {
		if ($field =~ /\A([^:]+):(.*)\z/) {
			$h{$1} = $2;
		} else {
			$h{_positional} = $field;
		}
	}
	return \%h;
}

# ---------------------------------------------------------------------------
# Private: metadata handlers
# ---------------------------------------------------------------------------

sub _handle_font {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	push @{ $self->{_score}{_fonts} }, {
		style    => $h->{Style}    // '',
		typeface => $h->{Typeface} // '',
		size     => defined $h->{Size} ? $h->{Size} + 0 : 0,
		bold     => ($h->{Bold}   // 'N') eq 'Y' ? 1 : 0,
		italic   => ($h->{Italic} // 'N') eq 'Y' ? 1 : 0,
	};
}

sub _handle_song_info {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	for my $key (qw(Title Author Lyricist Copyright Copyright1 Copyright2 Comments)) {
		$self->{_score}->set_metadata_field($key, $h->{$key})
			if exists $h->{$key};
	}
}

sub _handle_pg_setup {
	my ($self, $fields) = @_;
	my $h  = $self->_fields_to_hash($fields);
	my $ps = $self->{_score}->page_setup;
	%$ps = (%$ps, %$h);
}

sub _handle_add_staff {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	my $staff = Music::NWC2MusicXML::Staff->new(
		name  => $h->{Name}  // 'Staff',
		group => $h->{Group} // 'Standard',
	);
	$self->{_score}->add_staff($staff);
}

sub _handle_staff_properties {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	my $staff = $self->_current_staff_or_croak('StaffProperties');
	$staff->{_visible}         = ($h->{Visible} // 'Y') eq 'Y' ? 1 : 0;
	$staff->{_lines}           = $h->{Lines} // 5;
	$staff->{_ending_bar}      = $h->{EndingBar};
	$staff->{_channel}         = $h->{Channel} + 0 if defined $h->{Channel};
	$staff->{_with_next_staff} = $h->{WithNextStaff} if defined $h->{WithNextStaff};
	$staff->{_volume}          = $h->{Volume}    + 0 if defined $h->{Volume};
	$staff->{_stereo_pan}      = $h->{StereoPan} + 0 if defined $h->{StereoPan};
	$staff->{_muted}           = ($h->{Muted} // 'N') eq 'Y' ? 1 : 0;
}

sub _handle_staff_instrument {
	my ($self, $fields) = @_;
	my $h     = $self->_fields_to_hash($fields);
	my $staff = $self->_current_staff_or_croak('StaffInstrument');
	$staff->{_instrument} = {
		name  => $h->{Name}  // '',
		patch => $h->{Patch} // 0,
		trans => $h->{Trans} // 0,
	};
	if (defined $h->{DynVel} && length $h->{DynVel}) {
		my @keys = qw(ppp pp p mp mf f ff fff);
		my @vels = split /,/, $h->{DynVel};
		if (@vels == @keys) {
			my %vel_map;
			@vel_map{@keys} = map { $_ + 0 } @vels;
			$staff->{_dyn_vel} = \%vel_map;
		}
	}
}

# ---------------------------------------------------------------------------
# Private: initial-state handlers (clef/key/time -- before events begin)
# ---------------------------------------------------------------------------

sub _handle_clef {
	my ($self, $fields) = @_;
	my $h    = $self->_fields_to_hash($fields);
	my $type = $h->{Type} // 'Treble';

	unless (exists $VALID_CLEFS{$type}) {
		carp _fmt_msg('warn_bad_value', 'Clef.Type', $type, $self->{_line_no});
	}

	my $staff = $self->_current_staff_or_croak('Clef');
	if (!$staff->has_notes) {
		$staff->set_initial_clef($type);
	} else {
		$self->_append_event(Music::NWC2MusicXML::Event->new(
			type => 'Clef',
			data => { nwc_clef => $type },
		));
	}
}

sub _handle_key {
	my ($self, $fields) = @_;
	my $h   = $self->_fields_to_hash($fields);
	my $sig = $h->{Signature} // 'C';

	my $key_data = {
		signature => $sig,
		tonic     => $h->{Tonic} // '',
		fifths    => _fifths_from_signature($sig),
	};

	my $staff = $self->_current_staff_or_croak('Key');
	if (!$staff->has_notes) {
		$staff->set_initial_key($key_data);
	} else {
		$self->_append_event(Music::NWC2MusicXML::Event->new(
			type => 'Key',
			data => $key_data,
		));
	}
}

sub _handle_time_sig {
	my ($self, $fields) = @_;
	my $h   = $self->_fields_to_hash($fields);
	my $sig = $h->{Signature} // '4/4';

	my ($beats, $beat_type) = $sig =~ m{\A(\d+)/(\d+)\z};
	unless (defined $beats && defined $beat_type) {
		carp _fmt_msg('warn_bad_value', 'TimeSig.Signature', $sig, $self->{_line_no});
		($beats, $beat_type) = (4, 4);
	}

	my $ts_data = { beats => $beats + 0, beat_type => $beat_type + 0 };

	my $staff = $self->_current_staff_or_croak('TimeSig');
	if (!$staff->has_notes) {
		$staff->set_initial_timesig($ts_data);
	} else {
		$self->_append_event(Music::NWC2MusicXML::Event->new(
			type => 'TimeSig',
			data => $ts_data,
		));
	}
}

# ---------------------------------------------------------------------------
# Private: musical event handlers
# ---------------------------------------------------------------------------

sub _handle_tempo {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Tempo',
		data => {
			bpm  => $h->{Tempo} // 120,
			base => $h->{Base}  // 'Quarter',
		},
	));
}

sub _handle_note {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);

	my ($base_dur, $dots, $triplet, $artic, $is_grace) = _parse_dur_tokens($h->{Dur} // '4th');
	my $rational = Music::NWC2MusicXML::Event->rational_from_nwc_duration($base_dur, $dots);

	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => $rational,
		data     => {
			nwc_pos       => $h->{Pos} // '0',
			base_dur      => $base_dur,
			dots          => $dots,
			triplet       => $triplet,
			articulations => $artic,
			is_grace      => $is_grace,
			opts          => _parse_opts($h->{Opts}),
		},
	));
}

sub _handle_rest {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);

	my ($base_dur, $dots) = _parse_dur_tokens($h->{Dur} // '4th');
	my $rational = Music::NWC2MusicXML::Event->rational_from_nwc_duration($base_dur, $dots);

	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type     => 'Rest',
		duration => $rational,
		data     => {
			base_dur => $base_dur,
			dots     => $dots,
			opts     => _parse_opts($h->{Opts}),
		},
	));
}

sub _handle_chord {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);

	my ($base_dur, $dots, $triplet, $artic, $is_grace) = _parse_dur_tokens($h->{Dur} // '4th');
	my $rational = Music::NWC2MusicXML::Event->rational_from_nwc_duration($base_dur, $dots);

	# Pos field contains a comma-separated list of position strings.
	# Each entry: optional accidental prefix (#/b/n/##/bb/x) + signed integer + optional ^ (tie)
	my @positions = split /,/, ($h->{Pos} // '0');

	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type     => 'Chord',
		duration => $rational,
		data     => {
			nwc_positions => \@positions,
			base_dur      => $base_dur,
			dots          => $dots,
			triplet       => $triplet,
			articulations => $artic,
			is_grace      => $is_grace,
			opts          => _parse_opts($h->{Opts}),
		},
	));
}

sub _handle_bar {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	# NWC bar records carry an optional Style named field; plain |Bar| has none.
	my $style = $h->{Style} // $h->{_positional} // 'normal';
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Bar',
		data => { style => $style },
	));
}

# ---------------------------------------------------------------------------
# Private: duration / options parsing helpers
# ---------------------------------------------------------------------------

sub _parse_dur_tokens {
	my ($dur_str) = @_;
	my @tokens   = split /,/, ($dur_str // '4th');
	my $base     = shift(@tokens) // '4th';
	my ($dots, $triplet, $is_grace) = (0, undef, 0);
	my @artic;

	for my $tok (@tokens) {
		if    ($tok eq 'Dotted')                { $dots     = 1 }
		elsif ($tok eq 'DblDotted')             { $dots     = 2 }
		elsif ($tok =~ /\ATriplet(?:=(.+))?\z/) { $triplet  = $1 // 'Middle' }
		elsif ($tok eq 'Grace')                 { $is_grace = 1 }
		else                                    { push @artic, $tok }
	}

	return ($base, $dots, $triplet, \@artic, $is_grace);
}

sub _parse_opts {
	my ($opts_str) = @_;
	return {} unless defined $opts_str && length $opts_str;
	my %opts;
	for my $opt (split /,/, $opts_str) {
		if ($opt =~ /\A(\w+)=(.*)\z/) { $opts{$1} = $2 }
		else                        { $opts{$opt} = 1 }
	}
	return \%opts;
}

sub _handle_dynamic {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Dynamic',
		data => {
			marking   => $h->{Style} // $h->{_positional} // '',
			placement => $h->{Placement} // '',
		},
	));
}

sub _handle_dyn_variance {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'DynVariance',
		data => {
			style     => $h->{Style} // $h->{_positional} // '',
			placement => $h->{Placement} // '',
		},
	));
}

sub _handle_text {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Text',
		data => { text => $h->{Text} // '', placement => $h->{Placement} // '' },
	));
}

sub _handle_lyric {
	my ($self, $fields) = @_;
	my $h    = $self->_fields_to_hash($fields);
	my $text = $h->{Text} // '';
	# Syllabic type encoded by leading/trailing hyphens: strip them, infer type.
	my $starts_h = ($text =~ s/\A-//);
	my $ends_h   = ($text =~ s/-\z//);
	my $syllabic = $starts_h && $ends_h ? 'middle'
	             : $starts_h            ? 'end'
	             : $ends_h              ? 'begin'
	             :                        'single';
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Lyric',
		data => { text => $text, verse => $h->{Verse} // 1, syllabic => $syllabic },
	));
}

sub _handle_tie {
	my ($self, $fields) = @_;
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Tie',
		data => {},
	));
}

sub _handle_slur {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Slur',
		data => { _raw_fields => $h },
	));
}

sub _handle_beam {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Beam',
		data => { _raw_fields => $h },
	));
}

sub _handle_tuplet {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Tuplet',
		data => { _raw_fields => $h },
	));
}

sub _handle_instrument_change {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'Instrument',
		data => { name => $h->{Name} // '', patch => $h->{Patch} // 0 },
	));
}

sub _handle_flow_control {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'FlowControl',
		data => { directive => $h->{_positional} // $h->{Style} // '', extra => $h },
	));
}

sub _handle_tempo_variance {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);

	my $style = $h->{Style} // '';
	my $pos   = $h->{Pos}   // 0;
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type => 'TempoVariance',
		data => {
			style     => $style,
			placement => ($pos >= 0 ? 'above' : 'below'),
		},
	));
}

sub _handle_spacer {
	# Spacer is a graphical-layout hint with no MusicXML equivalent.
	# Per the preservation principle (musical meaning > graphical appearance)
	# it is silently discarded; no event, no warning.
	return;
}

sub _handle_rest_chord {
	my ($self, $fields) = @_;
	my $h = $self->_fields_to_hash($fields);

	# RestChord is a multi-voice construct: one layer rests while another
	# plays.  Full handling requires voice assignment (Phase 4).
	# Stored as UnsupportedEvent so the raw field data is preserved for
	# diagnostics and future implementation.
	$self->_append_event(Music::NWC2MusicXML::Event->new(
		type      => 'UnsupportedEvent',
		nwc_label => 'RestChord',
		data      => { _raw_fields => $h },
	));
}

# ---------------------------------------------------------------------------
# Private: helpers
# ---------------------------------------------------------------------------

sub _append_event {
	my ($self, $event) = @_;
	my $staff = $self->_current_staff_or_croak($event->type);
	$staff->add_event($event);
}

sub _current_staff_or_croak {
	my ($self, $context) = @_;
	my $staff = $self->{_score}->current_staff;
	croak _fmt_msg('error_no_staff', $context) unless defined $staff;
	return $staff;
}

sub _warn_unknown {
	my ($self, $type) = @_;
	carp _fmt_msg('warn_unknown_record', $type, $self->{_line_no});
}

sub _fifths_from_signature {
	my ($sig) = @_;
	return 0 unless defined $sig && length $sig;
	return 0 if $sig eq $KEY_SIG_NATURAL;

	# Signature is a comma-separated list of accidentals in circle-of-fifths order.
	# Each item ending in '#' is a sharp; each item ending in 'b' (after a letter) is a flat.
	my @acc = split /,/, $sig;
	return 0 unless @acc;

	if (index($acc[0], '#') >= 0) {
		return scalar @acc;       # positive = sharps
	} elsif (substr($acc[0], -1, 1) eq 'b') {
		return -(scalar @acc);    # negative = flats
	}
	return 0;
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

| Code                   | Meaning                                  | Resolution                        |
|------------------------|------------------------------------------|-----------------------------------|
| error_empty_input      | NWCTXT string is empty or undef          | Check NWC decoder                 |
| error_no_header        | Header line absent                       | Verify NWCTXT output from decoder |
| error_too_many_records | Record count exceeds MAX_RECORDS (1M)    | Probable corrupt input            |
| error_bad_record       | Record fails tokenisation                | File may be corrupt               |
| error_no_staff         | Musical event before any AddStaff        | NWCTXT may be truncated           |
| warn_unknown_record    | Unknown record type                      | New NWC version; file as UnsupportedEvent |
| warn_bad_value         | Field value not in recognised set        | NWC file may use newer syntax     |

=head1 LIMITATIONS

=over 4

=item * Note and Rest pitch/duration sub-field parsing is stubbed (Phase 2).

=item * Tuplet time-modification is not yet applied to affected events (Phase 4).

=item * The parser does not yet validate measure duration totals (Phase 3 / --validate).

=item * Multi-voice detection within a single staff is deferred to the MusicXML generator.

=back

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

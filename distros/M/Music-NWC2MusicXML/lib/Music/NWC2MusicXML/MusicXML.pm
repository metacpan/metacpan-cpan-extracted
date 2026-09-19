package Music::NWC2MusicXML::MusicXML;

use strict;
use warnings;
use autodie qw(:all);

our $VERSION = '0.001.0';

use Carp qw(croak carp);
use POSIX qw(floor);
use Readonly;
use List::Util qw(any);
use Scalar::Util qw(blessed);
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Event;

# ---------------------------------------------------------------------------
# MusicXML structural constants
# ---------------------------------------------------------------------------

# MusicXML version targeted (supported by MuseScore 3+)
Readonly::Scalar my $MUSICXML_VERSION => '4.0';

# DOCTYPE public/system identifiers
Readonly::Scalar my $DOCTYPE_PUBLIC =>
	'-//Recordare//DTD MusicXML 4.0 Partwise//EN';
Readonly::Scalar my $DOCTYPE_SYSTEM =>
	'http://www.musicxml.org/dtds/partwise.dtd';

# Default divisions per quarter note used as a fallback; the actual value is
# computed per-score from the LCM of all note-duration denominators.
Readonly::Scalar my $DEFAULT_DIVISIONS => 24;

# Maximum number of simultaneous open slurs per staff
Readonly::Scalar my $MAX_SLUR_NUMBER => 6;

# ---------------------------------------------------------------------------
# Clef mappings: NWC clef name -> { sign, line, [clef-octave-change] }
# ---------------------------------------------------------------------------
Readonly::Hash my %CLEF_MAP => (
	Treble     => { sign => 'G', line => 2 },
	Bass       => { sign => 'F', line => 4 },
	Alto       => { sign => 'C', line => 3 },
	Tenor      => { sign => 'C', line => 4 },
	Percussion => { sign => 'percussion' },
	Tab        => { sign => 'TAB' },
);

# ---------------------------------------------------------------------------
# Articulation mappings: NWC token (initial-cap) -> { element, group }
# group: 'articulations' | 'ornaments' | 'direct' (emitted directly in <notations>)
Readonly::Hash my %ARTICULATION_MAP => (
	Tenuto        => { element => 'tenuto',        group => 'articulations' },
	Staccato      => { element => 'staccato',      group => 'articulations' },
	Accent        => { element => 'accent',        group => 'articulations' },
	Marcato       => { element => 'strong-accent', group => 'articulations' },
	Staccatissimo => { element => 'staccatissimo', group => 'articulations' },
	Fermata       => { element => 'fermata',       group => 'direct'        },
	Trill         => { element => 'trill-mark',    group => 'ornaments'     },
	Mordent       => { element => 'mordent',       group => 'ornaments'     },
	Turn          => { element => 'turn',          group => 'ornaments'     },
);

# ---------------------------------------------------------------------------
# Dynamic markings: NWC -> MusicXML element
# ---------------------------------------------------------------------------
Readonly::Hash my %DYNAMIC_MAP => map { $_ => $_ }
	qw(pppp ppp pp p mp mf f ff fff ffff);

# ---------------------------------------------------------------------------
# Tempo base unit: NWC Base field -> { unit, dot, quarter_factor }
# quarter_factor converts noted BPM to quarter-note BPM for <sound tempo="..."/>
# ---------------------------------------------------------------------------
Readonly::Hash my %TEMPO_BASE_MAP => (
	'Whole'              => { unit => 'whole',   dot => 0, factor => 4    },
	'Half'               => { unit => 'half',    dot => 0, factor => 2    },
	'Quarter'            => { unit => 'quarter', dot => 0, factor => 1    },
	'Eighth'             => { unit => 'eighth',  dot => 0, factor => 0.5  },
	'Sixteenth'          => { unit => '16th',    dot => 0, factor => 0.25 },
	'Dotted Whole'       => { unit => 'whole',   dot => 1, factor => 6    },
	'Dotted Half'        => { unit => 'half',    dot => 1, factor => 3    },
	'Dotted Quarter'     => { unit => 'quarter', dot => 1, factor => 1.5  },
	'Dotted Eighth'      => { unit => 'eighth',  dot => 1, factor => 0.75 },
	'Dotted Sixteenth'   => { unit => '16th',    dot => 1, factor => 0.375 },
);

# ---------------------------------------------------------------------------
# Pitch-conversion constants
# ---------------------------------------------------------------------------

# Reference note (step_index, octave) for NWC position 0 = middle line (3rd from bottom) of each staff.
# Step indices: C=0, D=1, E=2, F=3, G=4, A=5, B=6
# Verified against Pilgrim.nwc: Bass pos -7 = A2 (A-drone), Treble pos -9 = D4 (tonic).
Readonly::Hash my %CLEF_REF => (
	Treble     => [ 6, 4 ],   # B4 (middle line)
	Bass       => [ 1, 3 ],   # D3 (middle line)
	Alto       => [ 0, 4 ],   # C4 (middle line)
	Tenor      => [ 5, 3 ],   # A3 (middle line)
	Percussion => [ 6, 4 ],   # B4 (treat as treble)
	Tab        => [ 6, 4 ],   # B4 (treat as treble)
);

# Diatonic step names indexed 0-6
Readonly::Array my @STEP_NAMES => qw(C D E F G A B);

# Circle-of-fifths order: sharps = F C G D A E B; flats = B E A D G C F
Readonly::Array my @SHARP_STEPS => ( 3, 0, 4, 1, 5, 2, 6 );
Readonly::Array my @FLAT_STEPS  => ( 6, 2, 5, 1, 4, 0, 3 );

# NWC accidental prefix -> [ semitone_alter, MusicXML accidental name ]
# P1: empty prefix and unknown prefixes fall back to key-signature alter (no accidental element).
# P2: 'x' is NWC's alias for '##' (double-sharp written as a cross).
Readonly::Hash my %ACCIDENTAL_MAP => (
	'#'  => [  1, 'sharp'        ],
	'##' => [  2, 'double-sharp' ],
	'x'  => [  2, 'double-sharp' ],
	'b'  => [ -1, 'flat'         ],
	'bb' => [ -2, 'double-flat'  ],
	'n'  => [  0, 'natural'      ],
);

# NWC base-duration name -> MusicXML type string
Readonly::Hash my %NWC_TYPE_MAP => (
	Whole  => 'whole',
	Half   => 'half',
	'4th'  => 'quarter',
	'8th'  => 'eighth',
	'16th' => '16th',
	'32nd' => '32nd',
	'64th' => '64th',
);

# Flow-control directive -> MusicXML element and/or words direction
Readonly::Hash my %FLOW_CONTROL_MAP => (
	Coda           => { element => 'coda'                      },
	Segno          => { element => 'segno'                     },
	DaCapo         => { words => 'D.C.'                        },
	DaCapoAlFine   => { words => 'D.C. al Fine'                },
	DaCapoAlCoda   => { words => 'D.C. al Coda'                },
	DalSegno       => { words => 'D.S.'                        },
	DalSegnoAlFine => { words => 'D.S. al Fine'                },
	DalSegnoAlCoda => { words => 'D.S. al Coda'                },
	Fine           => { words => 'Fine'                        },
	ToCoda         => { element => 'coda', words => 'To Coda'  },
);

Readonly::Hash my %MESSAGES => (
	error_bad_score      => 'generate: argument must be a Music::NWC2MusicXML::Score',
	error_no_staves      => 'Score contains no staves -- cannot generate MusicXML',
	error_write_failed   => 'Cannot write to output: %s',
	error_internal       => 'Internal error: %s',
	warn_unknown_clef    => 'Unrecognised NWC clef %s -- defaulting to Treble',
	warn_unknown_dynamic => 'Unrecognised dynamic marking %s',
	warn_unsupported_art => 'Unsupported articulation %s',
	warn_approx_bar      => 'Bar style %s approximated as regular',
);

=head1 NAME

Music::NWC2MusicXML::MusicXML - Convert an internal Score object to a MusicXML 4.0 document string.

=head1 VERSION

0.001.0

=head1 SYNOPSIS

    # --- Pattern 1: full pipeline from a .nwc file ---
    use Music::NWC2MusicXML::NWC;
    use Music::NWC2MusicXML::Parser;
    use Music::NWC2MusicXML::MusicXML;

    my $nwctxt = Music::NWC2MusicXML::NWC->read('my_score.nwc');
    my $score  = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
    my $xml    = Music::NWC2MusicXML::MusicXML->new->generate($score);

    # Write raw bytes -- the string is already pure ASCII (numeric entities
    # for any non-ASCII source characters).
    open my $fh, '>:raw', 'output.musicxml' or die $!;
    print $fh $xml;
    close $fh;

    # --- Pattern 2: custom indentation ---
    my $gen = Music::NWC2MusicXML::MusicXML->new(indent => "\t");
    my $xml = $gen->generate($score);

    # --- Pattern 3: validate the output with an external tool ---
    # (run in the shell after writing the file)
    # xmllint --noout output.musicxml

    # --- Pattern 4: generate and keep in memory for further processing ---
    my $xml_string = Music::NWC2MusicXML::MusicXML->new->generate($score);
    my @lines = split /\n/, $xml_string;
    my ($part_list) = grep { /part-list/ } @lines;

=head1 DESCRIPTION

C<Music::NWC2MusicXML::MusicXML> is the last stage of the NWC-to-MusicXML
pipeline.  It takes a C<Music::NWC2MusicXML::Score> object -- the internal
representation built by C<Music::NWC2MusicXML::Parser> -- and returns a
self-contained MusicXML 4.0 document as a plain string.

The generator knows nothing about the NWCTXT or NWC binary format.  Every
musical decision (pitches, durations, articulations, dynamics, tempo, key,
clef, copyright text) was already made by the parser.  The generator only
serialises the Score object tree into valid XML.

=head2 Divisions

MusicXML requires one integer, C<< <divisions> >>, that says how many ticks
equal one quarter note.  To represent every note duration exactly -- including
unusual tuplet values -- the generator scans all note durations across all
staves, collects the denominators of their rational representations, and
computes their least common multiple (LCM).  That LCM becomes
C<< <divisions> >>.  No duration is ever rounded or truncated.

=head2 Page layout and credits

The generator emits a C<< <defaults> >> block that records the actual page
size and margin values expressed in MusicXML tenths.  Without this block a
renderer cannot interpret the absolute coordinate values used by credit
elements, so title and copyright placement would be undefined.

Page dimensions default to A4 (210 x 297 mm) with 1.27 cm margins, which
match NWC's own defaults.  If the source NWC file contained a C<PgMargins>
record the parser stores the margin values in the Score's C<page_setup>
hashref and the generator reads them from there.

Each title, subtitle, and copyright line is emitted as its own separate
C<< <credit> >> element:

=over 4

=item * Title -- C<< <credit page="1"> >>; large font; centred near the top
of page 1.

=item * Subtitle (the NWC Author field) -- C<< <credit page="1"> >>; medium
font; centred directly below the title.

=item * Each copyright line -- C<< <credit> >> with B<no page attribute>;
this instructs conforming renderers to display the line on B<every> page.
One separate C<< <credit> >> element is used per line; putting multiple
C<< <credit-words> >> inside a single C<< <credit> >> causes many renderers
to display only the last one.

=back

=head2 Articulations

NWC encodes articulations as initial-capital tokens in the C<Dur:> field
(for example C<Tenuto>, C<Staccato>, C<Accent>).  The generator groups them
into the correct MusicXML wrapper:

=over 4

=item * C<< <articulations> >> -- tenuto, staccato, accent, strong-accent,
staccatissimo.

=item * C<< <ornaments> >> -- trill-mark, mordent, turn.

=item * Direct child of C<< <notations> >> -- fermata.

=back

The C<Slur> token is never emitted as an articulation; it is handled by the
slur-annotation pre-pass (see L</Slurs and ties> below).

=head2 Slurs and ties

A single pre-pass over all events in a staff (C<_annotate_events>) detects
slur arcs and tie pairs before the events are grouped into measures.  This
means arcs that cross a bar line are handled correctly.  Each event is
annotated with flags that the measure emitter reads when writing
C<< <slur> >> and C<< <tied> >> elements.

Tie detection uses the raw NWC position string as a key.  A C<^> suffix on a
position string (e.g. C<Pos:-7^>) means the note is tied forward; the
generator strips the suffix to match the tied-to note.

=head2 Hairpins (wedges)

NWC does not use standalone records for in-staff hairpins.  Instead it
attaches C<Opts:Crescendo> or C<Opts:Diminuendo> to every note and rest that
sits under the arc.  A second pre-pass (C<_annotate_wedges>) detects the
start and end of each arc by watching for transitions: the first event
carrying a hairpin flag starts the arc; the first event that drops the flag
closes it.  The wedge stop is emitted as a C<crescOff> direction immediately
after the last note of the arc.

=head2 Tempo variance

Markings such as C<Accelerando>, C<Ritardando>, C<Rallentando>, and
C<RitardandoToTempo> (rendered as "a tempo") are stored as C<TempoVariance>
events by the parser.  The generator converts them to italic
C<< <words> >> direction elements using the C<%TEMPO_VARIANCE_TEXT> table.

=head2 Part name resolution

Display names for each staff are resolved in three steps:

=over 4

=item 1. Use the NWC staff name, if it is not a generic default such as
C<Staff> or C<Staff-2>.

=item 2. Fall back to the MIDI instrument name.

=item 3. Fall back to the positional name C<Staff-N> (1-based).

=back

After all candidates are found, any name that appears on more than one staff
is replaced with C<Staff-N> to guarantee unique C<< <part-name> >> values.

=head1 COMMON PITFALLS

=over 4

=item B<Opening the output file in text mode>

The output string is pure ASCII (all non-ASCII characters are escaped as
numeric XML entities).  Opening the output file with C<< '>:encoding(UTF-8)' >>
is harmless but unnecessary; opening it with C<< '>:encoding(Latin-1)' >> or
a similar 8-bit encoding and then printing a string that contains non-ASCII
bytes would corrupt the file.  The safest choice is C<< '>:raw' >>.

=item B<Multiple copyright lines in one credit element>

If you call C<_emit_credits> and place two C<< <credit-words> >> children
inside a single C<< <credit> >> element, most renderers (including MuseScore
and Finale) display only the B<last> C<< <credit-words> >> and silently
discard the rest.  This module uses one C<< <credit> >> per copyright line to
avoid this.

=item B<Missing defaults section>

The absolute coordinates in C<< <credit> >> elements (C<default-x>,
C<default-y>) are measured in MusicXML "tenths" from the bottom-left corner
of the page.  They are meaningless to a renderer unless a C<< <defaults> >>
block defines the page size and the tenths-per-mm scaling factor.  This module
always emits C<< <defaults> >> before any C<< <credit> >> elements.

=item B<Two separate rights elements in identification>

C<< <identification> >> accepts only one C<< <rights> >> child in practice;
a second one shadows the first.  This module joins multiple copyright lines
with a newline character inside a single C<< <rights> >> element.

=item B<Slur token treated as an articulation>

NWC encodes slurs as C<Slur> in the same token list as articulations.  Do not
add C<Slur> to C<%ARTICULATION_MAP>; the slur-annotation pre-pass handles it.
If C<Slur> were also emitted as an articulation element the output XML would be
invalid.

=item B<Score with no staves>

Calling C<generate> on a C<Score> object that has no staves will C<croak>
immediately.  Always check that the parser produced at least one staff before
calling the generator.

=back

=head1 ENCODING

=over 4

=item B<Input (Score metadata fields)>

Metadata strings (Title, Author, Copyright1, Copyright2, etc.) may contain any
Unicode characters, including non-ASCII letters, accented characters, and the
copyright symbol (U+00A9).  The NWC binary decoder may deliver these as Latin-1
bytes; once stored in Perl scalars they are handled correctly as long as they
pass through C<_xml_escape> before being written to the output.

=item B<Output (the generated XML string)>

The string returned by C<generate> is B<pure 7-bit ASCII>.  Every character
whose code point is above 127 is converted to a numeric XML character
reference (C<&#N;>), for example C<&#169;> for the copyright symbol.  The XML
declaration at the top of the document reads C<encoding="UTF-8">, which
remains correct because numeric character references are valid in any XML
encoding.

=item B<Emojis and full Unicode>

Emoji and supplementary-plane characters (code points above U+FFFF) are not
tested but will be escaped correctly by C<_xml_escape> as long as Perl has
decoded them to proper Unicode code points (i.e. C<utf8::decode> has been
applied or the string was read with a C<:utf8> layer).  Raw multi-byte UTF-8
bytes that have B<not> been decoded will be escaped byte-by-byte and will
produce incorrect numeric references.

=back

=cut

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

=head2 new

Create a new generator object.

=head3 Purpose

Factory constructor.  Creates a configured generator ready to call C<generate>
one or more times.  The same generator instance can be used to process
multiple Score objects; each C<generate> call is independent.

=head3 Arguments

All arguments are named (passed as a flat key/value list) and optional.

=over 4

=item C<indent>

The string used for one level of XML indentation.  Defaults to two spaces.
Pass C<"\t"> for tab indentation.  Only affects whitespace; the XML content
is identical regardless of the indent setting.

=item C<diagnostics>

A C<Music::NWC2MusicXML::Diagnostics> instance for routing warning messages.
When omitted, warnings are sent directly to C<carp>.

=back

=head3 Returns

A blessed C<Music::NWC2MusicXML::MusicXML> object.

=head3 Side Effects

None.

=head3 Usage Example

    # Default (two-space indent)
    my $gen = Music::NWC2MusicXML::MusicXML->new;

    # Tab indent
    my $gen = Music::NWC2MusicXML::MusicXML->new(indent => "\t");

=head3 API SPECIFICATION

=head4 Input

    indent      : SCALAR   (optional, default '  ')
    diagnostics : OBJECT   Music::NWC2MusicXML::Diagnostics  (optional)

=head4 Output

    Music::NWC2MusicXML::MusicXML object

=head3 MESSAGES

This method does not emit any diagnostic messages.

=cut

sub new {
	my ($class, %input) = @_;
	my $args = validate_strict(
		schema => {
			diagnostics => { type => 'object', optional => 1 },
			indent      => { type => 'scalar', optional => 1, default => '  ' },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $self = bless {
		_diagnostics => $args->{diagnostics},
		_indent      => $args->{indent},
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Public: generate
# ---------------------------------------------------------------------------

=head2 generate

Convert a C<Music::NWC2MusicXML::Score> object to a MusicXML 4.0 document and
return the complete document as a string.

=head3 Purpose

Top-level entry point.  Orchestrates, in order:

=over 4

=item 1. XML declaration and DOCTYPE header.

=item 2. Page layout geometry (C<< <defaults> >>).

=item 3. Work title (C<< <work> >>).

=item 4. Identification metadata: composer, lyricist, rights (C<< <identification> >>).

=item 5. Visual credits: title, subtitle, and copyright lines (C<< <credit> >> elements).

=item 6. Part list: one C<< <score-part> >> per staff (C<< <part-list> >>).

=item 7. Musical content: one C<< <part> >> per staff, each containing numbered
measures with notes, rests, dynamics, tempo, articulations, slurs, ties,
and wedge hairpins.

=back

Each staff is processed by a two-stage pipeline:

=over 4

=item Stage 1 -- annotation pre-passes.

C<_annotate_events> detects slur arcs and tie pairs across the entire staff
before measure grouping.  C<_annotate_wedges> detects hairpin (crescendo /
diminuendo) arcs stored as per-note C<Opts:> flags.  Both passes store their
results in a shared C<%ann> hash keyed by stringified event reference.

=item Stage 2 -- measure emission.

Events are gathered into measure-sized groups separated by C<Bar> events.
For each measure, C<_emit_measure> serialises notes, rests, directions, and
mid-staff attribute changes, consulting C<%ann> for slur, tie, and wedge
annotations.

=back

=head3 Arguments

=over 4

=item C<$score>

A C<Music::NWC2MusicXML::Score> object (required).  Must contain at least one
staff; otherwise the method croaks.

=back

=head3 Returns

A scalar string holding the complete MusicXML 4.0 document.  The string is
pure 7-bit ASCII: all non-ASCII source characters are replaced with numeric
XML character references (C<&#N;>).  The XML declaration at the top of the
string declares C<encoding="UTF-8">, which is correct.

The string ends with a single newline character.

=head3 Side Effects

May issue warnings via C<carp> for unsupported or unrecognised values
(unknown clef, unknown dynamic marking, unsupported articulation token,
approximate barline style).

=head3 Usage Example

    my $xml = $gen->generate($score);

    # Write to a file -- ':raw' is sufficient; the string is pure ASCII.
    open my $fh, '>:raw', 'out.musicxml' or die $!;
    print $fh $xml;
    close $fh;

=head3 API SPECIFICATION

=head4 Input

    $score : Music::NWC2MusicXML::Score  (required, must have staff_count > 0)

=head4 Output

    SCALAR  -- complete MusicXML 4.0 document, pure 7-bit ASCII, newline-terminated

=head3 MESSAGES

| Code                | Meaning                                  | Resolution                      |
|---------------------|------------------------------------------|---------------------------------|
| error_bad_score     | Argument is not a Score object           | Pass the object returned by Parser |
| error_no_staves     | Score has zero staves                    | Confirm the parser found AddStaff records |
| warn_unknown_clef   | NWC clef name not in CLEF_MAP            | Treble used as fallback         |
| warn_unknown_dynamic| Dynamic marking not in DYNAMIC_MAP       | Direction element omitted       |
| warn_unsupported_art| Articulation token not in ARTICULATION_MAP| Mark omitted; warning issued   |
| warn_approx_bar     | Barline style has no direct MusicXML map | Regular barline used            |

=cut

sub generate {
	my ($self, $score) = @_;

	croak _fmt_msg('error_bad_score')
		unless blessed($score) && $score->isa('Music::NWC2MusicXML::Score');

	croak _fmt_msg('error_no_staves')
		unless $score->staff_count > 0;

	# Calculate the divisions value from all note durations in the score.
	my $divisions = $self->_calculate_divisions($score);

	my @out;

	push @out, '<?xml version="1.0" encoding="UTF-8"?>';
	push @out, sprintf('<!DOCTYPE score-partwise PUBLIC "%s" "%s">',
		$DOCTYPE_PUBLIC, $DOCTYPE_SYSTEM);
	push @out, sprintf('<score-partwise version="%s">', $MUSICXML_VERSION);

	my $layout = _compute_page_layout($score->page_setup // {});

	push @out, $self->_emit_work($score->metadata);
	push @out, $self->_emit_identification($score->metadata);
	push @out, $self->_emit_defaults($layout, $score->fonts);
	push @out, $self->_emit_credits($score->metadata, $layout);
	push @out, $self->_emit_part_list($score->staves);
	push @out, $self->_emit_parts($score->staves, $divisions);

	push @out, '</score-partwise>';

	return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# Private: page layout constants and helpers
# ---------------------------------------------------------------------------

# Standard MusicXML scaling: 40 tenths per staff space, 7.2175 mm per space.
Readonly::Scalar my $MM_PER_SPACE  => 7.2175;
Readonly::Scalar my $TENTHS_PER_SPACE => 40;
Readonly::Scalar my $TENTHS_PER_MM => $TENTHS_PER_SPACE / $MM_PER_SPACE;

# Default to A4 paper (210 x 297 mm); most common in international music publishing.
Readonly::Scalar my $DEFAULT_PAGE_W_MM => 210.0;
Readonly::Scalar my $DEFAULT_PAGE_H_MM => 297.0;
Readonly::Scalar my $DEFAULT_MARGIN_CM => 1.27;   # standard NWC default

# Derive page geometry in tenths from PgSetup/PgMargins fields (cm margins).
# Returns a hashref: page_height, page_width, margin_l, margin_r, margin_t,
# margin_b, center_x, right_x.
sub _compute_page_layout {
	my ($ps) = @_;
	$ps //= {};

	# Margins: NWC stores them in cm (Left/Top/Right/Bottom from PgMargins).
	# When a side is absent, fall back to Left, then the hardcoded default.
	my $left   = $ps->{Left}   // $DEFAULT_MARGIN_CM;
	my $right  = $ps->{Right}  // $left;
	my $top    = $ps->{Top}    // $left;
	my $bottom = $ps->{Bottom} // $left;

	my $margin_l = $left   * 10 * $TENTHS_PER_MM;
	my $margin_r = $right  * 10 * $TENTHS_PER_MM;
	my $margin_t = $top    * 10 * $TENTHS_PER_MM;
	my $margin_b = $bottom * 10 * $TENTHS_PER_MM;

	my $page_h = $DEFAULT_PAGE_H_MM * $TENTHS_PER_MM;
	my $page_w = $DEFAULT_PAGE_W_MM * $TENTHS_PER_MM;

	return {
		page_height => $page_h,
		page_width  => $page_w,
		margin_l    => $margin_l,
		margin_r    => $margin_r,
		margin_t    => $margin_t,
		margin_b    => $margin_b,
		center_x    => $page_w / 2,
		right_x     => $page_w - $margin_r,
	};
}

sub _emit_defaults {
	my ($self, $layout, $fonts) = @_;
	$fonts //= [];
	my @out;
	my $i = $self->{_indent};

	my $ph = sprintf '%.2f', $layout->{page_height};
	my $pw = sprintf '%.2f', $layout->{page_width};
	my $ml = sprintf '%.2f', $layout->{margin_l};
	my $mr = sprintf '%.2f', $layout->{margin_r};
	my $mt = sprintf '%.2f', $layout->{margin_t};
	my $mb = sprintf '%.2f', $layout->{margin_b};

	push @out, '<defaults>';
	push @out, "${i}<scaling>";
	push @out, "${i}${i}<millimeters>$MM_PER_SPACE</millimeters>";
	push @out, "${i}${i}<tenths>$TENTHS_PER_SPACE</tenths>";
	push @out, "${i}</scaling>";
	push @out, "${i}<page-layout>";
	push @out, "${i}${i}<page-height>$ph</page-height>";
	push @out, "${i}${i}<page-width>$pw</page-width>";
	push @out, "${i}${i}<page-margins type=\"both\">";
	push @out, "${i}${i}${i}<left-margin>$ml</left-margin>";
	push @out, "${i}${i}${i}<right-margin>$mr</right-margin>";
	push @out, "${i}${i}${i}<top-margin>$mt</top-margin>";
	push @out, "${i}${i}${i}<bottom-margin>$mb</bottom-margin>";
	push @out, "${i}${i}</page-margins>";
	push @out, "${i}</page-layout>";

	# Font declarations from NWC Font records (word-font then lyric-font per schema order)
	my ($word_font, $lyric_font);
	for my $font (@$fonts) {
		next unless length($font->{typeface} // '');
		my $style = $font->{style} // '';
		if ($style eq 'StaffLyric' && !defined $lyric_font) {
			$lyric_font = $font;
		} elsif ($style =~ /\AStaff/i && !defined $word_font) {
			$word_font = $font;
		}
	}
	for my $pair ([$word_font, 'word-font'], [$lyric_font, 'lyric-font']) {
		my ($font, $elem) = @$pair;
		next unless defined $font;
		my $tf  = _xml_escape($font->{typeface} // '');
		my $sz  = $font->{size} ? " font-size=\"$font->{size}\"" : '';
		my $wt  = $font->{bold}   ? ' font-weight="bold"'   : '';
		my $fst = $font->{italic} ? ' font-style="italic"' : '';
		push @out, "${i}<$elem font-family=\"$tf\"${sz}${wt}${fst}/>";
	}

	push @out, '</defaults>';
	return @out;
}

# ---------------------------------------------------------------------------
# Private: top-level sections
# ---------------------------------------------------------------------------

sub _emit_work {
	my ($self, $meta) = @_;
	my @out;
	my $i = $self->{_indent};
	push @out, '<work>';
	push @out, "${i}<work-title>" . _xml_escape($meta->{Title} // '') . '</work-title>'
		if $meta->{Title};
	push @out, '</work>';
	return @out;
}

sub _emit_identification {
	my ($self, $meta) = @_;
	my @out;
	my $i = $self->{_indent};
	push @out, '<identification>';
	push @out, "${i}<creator type=\"composer\">"
		. _xml_escape($meta->{Author} // '') . '</creator>'
		if $meta->{Author};
	push @out, "${i}<creator type=\"lyricist\">"
		. _xml_escape($meta->{Lyricist} // '') . '</creator>'
		if $meta->{Lyricist};
	# Combine all copyright lines into one <rights> element; multiple <rights>
	# elements cause renderers to discard all but the last.
	my @cr_lines;
	if (defined $meta->{Copyright1} || defined $meta->{Copyright2}) {
		push @cr_lines, $meta->{Copyright1}
			if defined $meta->{Copyright1} && length $meta->{Copyright1};
		push @cr_lines, $meta->{Copyright2}
			if defined $meta->{Copyright2} && length $meta->{Copyright2};
	} elsif (defined $meta->{Copyright} && length $meta->{Copyright}) {
		push @cr_lines, $meta->{Copyright};
	}
	push @out, "${i}<rights>" . _xml_escape(join "\n", @cr_lines) . '</rights>'
		if @cr_lines;
	push @out, "${i}<encoding>";
	push @out, "${i}${i}<software>Music::NWC2MusicXML $VERSION</software>";
	push @out, "${i}</encoding>";
	if (defined $meta->{Comments} && length($meta->{Comments} // '')) {
		push @out, "${i}<miscellaneous>";
		push @out, "${i}${i}<miscellaneous-field name=\"comments\">"
			. _xml_escape($meta->{Comments}) . '</miscellaneous-field>';
		push @out, "${i}</miscellaneous>";
	}
	push @out, '</identification>';
	return @out;
}

sub _emit_credits {
	my ($self, $meta, $layout) = @_;
	$layout //= _compute_page_layout({});
	my @out;
	my $i = $self->{_indent};

	my $cx  = sprintf '%.2f', $layout->{center_x};
	my $ty  = sprintf '%.2f', $layout->{page_height} - $layout->{margin_t};
	my $sy  = sprintf '%.2f', $layout->{page_height} - $layout->{margin_t} - 60;
	my $bot = $layout->{margin_b};

	# Title credit on page 1 (large, centred near top)
	if (defined $meta->{Title} && length $meta->{Title}) {
		push @out, '<credit page="1">';
		push @out, "${i}<credit-type>title</credit-type>";
		push @out, "${i}<credit-words"
			. " default-x=\"$cx\" default-y=\"$ty\""
			. ' justify="center" valign="top"'
			. ' font-size="24"'
			. '>' . _xml_escape($meta->{Title}) . '</credit-words>';
		push @out, '</credit>';
	}

	# Subtitle credit on page 1 (centred, just below title)
	if (defined $meta->{Author} && length $meta->{Author}) {
		push @out, '<credit page="1">';
		push @out, "${i}<credit-type>subtitle</credit-type>";
		push @out, "${i}<credit-words"
			. " default-x=\"$cx\" default-y=\"$sy\""
			. ' justify="center" valign="top"'
			. ' font-size="14"'
			. '>' . _xml_escape($meta->{Author}) . '</credit-words>';
		push @out, '</credit>';
	}

	# Copyright lines: each gets its OWN <credit> element (no page attribute ->
	# appears on every page). Multiple <credit-words> in one <credit> cause
	# renderers to show only the last element.
	my @cr_lines;
	if (defined $meta->{Copyright1} || defined $meta->{Copyright2}) {
		push @cr_lines, $meta->{Copyright1}
			if defined $meta->{Copyright1} && length $meta->{Copyright1};
		push @cr_lines, $meta->{Copyright2}
			if defined $meta->{Copyright2} && length $meta->{Copyright2};
	} elsif (defined $meta->{Copyright} && length $meta->{Copyright}) {
		push @cr_lines, $meta->{Copyright};
	}

	# Stack lines from bottom margin upward: last line at margin, each prior
	# line 14 tenths higher.
	my $line_step = 14;
	my $n         = scalar @cr_lines;
	for my $idx (0 .. $#cr_lines) {
		my $y = sprintf '%.2f', $bot + $line_step * ($n - 1 - $idx);
		push @out, '<credit>';
		push @out, "${i}<credit-type>rights</credit-type>";
		push @out, "${i}<credit-words"
			. " default-x=\"$cx\" default-y=\"$y\""
			. ' justify="center" valign="bottom"'
			. ' font-size="10"'
			. '>' . _xml_escape($cr_lines[$idx]) . '</credit-words>';
		push @out, '</credit>';
	}

	return @out;
}

sub _emit_part_list {
	my ($self, $staves) = @_;
	my @out;
	my $i = $self->{_indent};

	my @names  = _resolve_part_names($staves);
	my @groups = _compute_groups($staves);

	push @out, '<part-list>';
	my $part_id = 1;
	for my $staff (@$staves) {
		my $idx = $part_id - 1;

		# Groups starting before this score-part (outer before inner)
		for my $g (sort { $a->{num} <=> $b->{num} } grep { $_->{start} == $idx } @groups) {
			push @out, "${i}<part-group type=\"start\" number=\"$g->{num}\">";
			push @out, "${i}${i}<group-symbol>$g->{symbol}</group-symbol>";
			push @out, "${i}${i}<group-barline>$g->{bars}</group-barline>";
			push @out, "${i}</part-group>";
		}

		my $id   = "P$part_id";
		my $name = _xml_escape($names[$idx]);
		push @out, "${i}<score-part id=\"$id\">";
		my $print_attr = ($staff->{_visible} // 1) ? '' : ' print-object="no"';
		push @out, "${i}${i}<part-name${print_attr}>$name</part-name>";
		my $instr = $staff->instrument;
		if ($instr && $instr->{name}) {
			push @out, "${i}${i}<score-instrument id=\"${id}-I1\">";
			push @out, "${i}${i}${i}<instrument-name>"
				. _xml_escape($instr->{name}) . '</instrument-name>';
			push @out, "${i}${i}</score-instrument>";
			if (defined $instr->{patch}) {
				my $chan = $staff->{_channel} // 1;
				push @out, "${i}${i}<midi-instrument id=\"${id}-I1\">";
				push @out, "${i}${i}${i}<midi-channel>$chan</midi-channel>";
				push @out, "${i}${i}${i}<midi-program>"
					. ($instr->{patch} + 1) . '</midi-program>';
				push @out, "${i}${i}</midi-instrument>";
			}
		}
		push @out, "${i}</score-part>";

		# Groups stopping after this score-part (inner before outer)
		for my $g (sort { $b->{num} <=> $a->{num} } grep { $_->{end} == $idx } @groups) {
			push @out, "${i}<part-group type=\"stop\" number=\"$g->{num}\"/>";
		}

		$part_id++;
	}
	push @out, '</part-list>';
	return @out;
}

# Compute bracket/brace grouping structure from WithNextStaff flags.
# Returns a list of group hashrefs: {num, start, end, symbol, bars}.
# Bracket groups are numbered before Brace groups so outer comes first.
sub _compute_groups {
	my ($staves) = @_;
	my @all_groups;
	my $group_num = 1;

	for my $sym (qw(Bracket Brace)) {
		my $i = 0;
		while ($i < @$staves) {
			my $wnxs  = $staves->[$i]{_with_next_staff} // '';
			my %flags = map { $_ => 1 } split /,/, $wnxs;

			if ($flags{$sym}) {
				my $start        = $i;
				my $connect_bars = $flags{ConnectBars} ? 'yes' : 'no';
				# Extend the group while consecutive staves carry the same flag.
				while ($i < @$staves - 1) {
					my $cur = $staves->[$i]{_with_next_staff} // '';
					my %cf  = map { $_ => 1 } split /,/, $cur;
					last unless $cf{$sym};
					$i++;
				}
				push @all_groups, {
					num    => $group_num++,
					start  => $start,
					end    => $i,
					symbol => lc($sym),
					bars   => $connect_bars,
				} if $i > $start;
				$i++;
			} else {
				$i++;
			}
		}
	}

	return @all_groups;
}

# ---------------------------------------------------------------------------
# Private: part-name resolution
# ---------------------------------------------------------------------------

# Resolve a display name for every staff, applying a three-level priority:
#   1. The NWC staff name, if it is not a generic default.
#   2. The MIDI instrument name, if distinct across all staves using it.
#   3. "Staff-N" (1-based) as the unconditional last resort.
#
# After candidates are chosen, any name that appears more than once is
# replaced with "Staff-N" to guarantee unique part names in the output.
sub _resolve_part_names {
	my ($staves) = @_;

	# Build candidates
	my @candidates;
	my $n = 1;
	for my $staff (@$staves) {
		push @candidates, _candidate_part_name($staff, $n++);
	}

	# Count how many staves share each candidate name
	my %freq;
	$freq{$_}++ for @candidates;

	# Replace any duplicated name with a positional "Staff-N" fallback
	my @resolved;
	my $pos = 1;
	for my $cand (@candidates) {
		push @resolved, $freq{$cand} > 1 ? "Staff-$pos" : $cand;
		$pos++;
	}

	return @resolved;
}

# Return a candidate name for one staff before deduplication.
sub _candidate_part_name {
	my ($staff, $part_num) = @_;
	my $name = $staff->name // '';

	# Accept the NWC name unless it matches NWC's own generic defaults
	# ("Staff", "Staff-0" .. "Staff-99").
	return $name if length $name && $name !~ /^Staff(?:-\d+)?$/i;

	# Try the instrument name recorded in the MIDI settings.
	my $instr = $staff->instrument // {};
	return $instr->{name}
		if defined $instr->{name} && length $instr->{name};

	# Positional fallback: 1-based "Staff-N".
	return "Staff-$part_num";
}

sub _emit_parts {
	my ($self, $staves, $divisions) = @_;
	my @out;
	my $part_id = 1;
	for my $staff (@$staves) {
		push @out, $self->_emit_part("P$part_id", $staff, $divisions);
		$part_id++;
	}
	return @out;
}

sub _emit_part {
	my ($self, $id, $staff, $divisions) = @_;
	my @out;

	push @out, "<part id=\"$id\">";

	my $measure_no = 1;
	my @pending    = ();
	my $first      = 1;
	my $prev_bar   = 'normal';

	# $clef_start / $key_start = state at the beginning of the current measure.
	# $clef_now   / $key_now   = state updated live as we scan events.
	# They diverge when Clef/Key events appear mid-measure; at each Bar we
	# commit the live values as the start-of-next-measure state.
	my $clef_start  = $staff->initial_clef // 'Treble';
	my $key_start   = ($staff->initial_key  // {})->{fifths} // 0;
	my $clef_now    = $clef_start;
	my $key_now     = $key_start;

	# Expose per-staff DynVel map for _emit_dynamic to use during this part.
	$self->{_dyn_vel} = $staff->{_dyn_vel};

	# Pre-annotate all events with slur/tie and wedge metadata in one pass
	# so that arcs crossing bar lines are handled correctly.
	my $ann = $self->_annotate_events($staff->events);
	$self->_annotate_wedges($staff->events, $ann);
	$self->_annotate_lyrics($staff->events, $ann);

	for my $event (@{ $staff->events }) {
		my $type = $event->type;

		if ($type eq 'Bar') {
			my $bar_style = $event->data->{style} // 'normal';
			push @out, $self->_emit_measure(
				$measure_no++, \@pending, $staff, $divisions,
				$first, $clef_start, $key_start, $prev_bar, $bar_style, $ann
			);
			@pending    = ();
			$first      = 0;
			$prev_bar   = $bar_style;
			$clef_start = $clef_now;   # carry updated state to next measure
			$key_start  = $key_now;

		} elsif ($type eq 'Clef') {
			$clef_now = $event->data->{nwc_clef} // $clef_now;
			push @pending, $event;     # included so _emit_measure can emit <attributes>

		} elsif ($type eq 'Key') {
			$key_now = ($event->data // {})->{fifths} // 0;
			push @pending, $event;

		} else {
			push @pending, $event;
		}
	}

	if (@pending || $measure_no == 1) {
		push @out, $self->_emit_measure(
			$measure_no, \@pending, $staff, $divisions,
			$first, $clef_start, $key_start, $prev_bar,
			$staff->{_ending_bar} // 'normal', $ann
		);
	}

	delete $self->{_dyn_vel};
	push @out, "</part>";
	return @out;
}

sub _emit_measure {
	my ($self, $number, $events, $staff, $divisions, $is_first,
	    $clef, $key_fifths, $prev_bar, $bar_style, $ann) = @_;
	my $curr_clef  = $clef       // 'Treble';
	my $curr_key   = $key_fifths // 0;
	$prev_bar  //= 'normal';
	$bar_style //= 'normal';
	$ann       //= {};

	my @out;
	my $i   = $self->{_indent};
	my $pad = $i;
	my $bar_accidentals = {};   # pitch_key -> alter; reset each measure

	push @out, "${pad}<measure number=\"$number\">";

	if ($prev_bar eq 'MasterRepeatOpen' || $prev_bar eq 'LocalRepeatOpen') {
		push @out, "${pad}${i}<barline location=\"left\">";
		push @out, "${pad}${i}${i}<bar-style>heavy-light</bar-style>";
		push @out, "${pad}${i}${i}<repeat direction=\"forward\"/>";
		push @out, "${pad}${i}</barline>";
	}

	if ($is_first) {
		push @out, $self->_emit_attributes($staff, $divisions, $pad . $i);
		# Emit MIDI playback volume/pan at the start of the first measure.
		my ($vol, $pan) = ($staff->{_volume}, $staff->{_stereo_pan});
		if (defined $vol || defined $pan) {
			my @sa;
			push @sa, sprintf('dynamics="%d"', int($vol * 100 / 127 + 0.5)) if defined $vol;
			push @sa, sprintf('pan="%d"',      int(($pan - 64) * 90 / 63 + 0.5)) if defined $pan;
			push @out, "${pad}${i}<sound " . join(' ', @sa) . '/>' if @sa;
		}
	}

	for my $event (@$events) {
		my $type   = $event->type;
		my $ev_ann = $ann->{"$event"} // {};

		if ($type eq 'TimeSig') {
			push @out, $self->_emit_time_change($event->data // {}, $pad . $i);

		} elsif ($type eq 'Clef') {
			$curr_clef = $event->data->{nwc_clef} // $curr_clef;
			push @out, $self->_emit_clef_change($curr_clef, $pad . $i);

		} elsif ($type eq 'Key') {
			my $kd = $event->data // {};
			$curr_key = $kd->{fifths} // 0;
			push @out, $self->_emit_key_change($kd, $pad . $i);

		} elsif ($type eq 'Tempo') {
			my $d = $event->data // {};
			push @out, $self->_emit_tempo(
				$d->{bpm}, $d->{base}, $pad . $i);

		} elsif ($type eq 'Dynamic') {
			my $d = $event->data // {};
			push @out, $self->_emit_dynamic(
				$d->{marking}, $d->{placement}, $pad . $i);

		} elsif ($type eq 'DynVariance') {
			my $d = $event->data // {};
			push @out, $self->_emit_wedge(
				$d->{style}, $d->{placement}, $pad . $i);

		} elsif ($type eq 'TempoVariance') {
			my $d = $event->data // {};
			push @out, $self->_emit_tempo_variance(
				$d->{style}, $d->{placement}, $pad . $i);

		} elsif ($type eq 'Text') {
			my $d = $event->data // {};
			push @out, $self->_emit_text_direction(
				$d->{text}, $d->{placement}, $pad . $i);

		} elsif ($type eq 'FlowControl') {
			my $d = $event->data // {};
			push @out, $self->_emit_flow_control($d->{directive}, $pad . $i);

		} elsif ($type eq 'Instrument') {
			my $d = $event->data // {};
			push @out, $self->_emit_instrument_change(
				$d->{name}, $d->{patch}, $pad . $i);

		} elsif ($type eq 'Note') {
			push @out, $self->_emit_wedge($ev_ann->{wedge_start}, undef, $pad . $i)
				if $ev_ann->{wedge_start};
			push @out, $self->_emit_note_event(
				$event, $curr_clef, $curr_key, $divisions, $pad . $i, 0, $ev_ann, $bar_accidentals);
			push @out, $self->_emit_wedge('crescOff', undef, $pad . $i)
				if $ev_ann->{wedge_stop_after};
		} elsif ($type eq 'Rest') {
			push @out, $self->_emit_wedge($ev_ann->{wedge_start}, undef, $pad . $i)
				if $ev_ann->{wedge_start};
			push @out, $self->_emit_rest_event($event, $divisions, $pad . $i, $ev_ann);
			push @out, $self->_emit_wedge('crescOff', undef, $pad . $i)
				if $ev_ann->{wedge_stop_after};
		} elsif ($type eq 'Chord') {
			push @out, $self->_emit_wedge($ev_ann->{wedge_start}, undef, $pad . $i)
				if $ev_ann->{wedge_start};
			push @out, $self->_emit_chord_event(
				$event, $curr_clef, $curr_key, $divisions, $pad . $i, $ev_ann, $bar_accidentals);
			push @out, $self->_emit_wedge('crescOff', undef, $pad . $i)
				if $ev_ann->{wedge_stop_after};
		}
	}

	if ($bar_style eq 'MasterRepeatClose') {
		push @out, "${pad}${i}<barline location=\"right\">";
		push @out, "${pad}${i}${i}<bar-style>light-heavy</bar-style>";
		push @out, "${pad}${i}${i}<repeat direction=\"backward\"/>";
		push @out, "${pad}${i}</barline>";
	} elsif ($bar_style eq 'Double') {
		push @out, "${pad}${i}<barline location=\"right\">";
		push @out, "${pad}${i}${i}<bar-style>light-light</bar-style>";
		push @out, "${pad}${i}</barline>";
	} elsif ($bar_style eq 'SectionClose' || $bar_style eq 'LocalRepeatClose') {
		push @out, "${pad}${i}<barline location=\"right\">";
		push @out, "${pad}${i}${i}<bar-style>light-heavy</bar-style>";
		push @out, "${pad}${i}</barline>";
	}

	push @out, "${pad}</measure>";
	return @out;
}

# ---------------------------------------------------------------------------
# Private: slur / tie annotation pass
# ---------------------------------------------------------------------------

# Walk all events in a staff once and build an annotation hashref keyed by
# stringified event reference.  Each value is a hashref with:
#   slur_start      => 1   this note opens a slur arc
#   slur_stop       => 1   this note closes a slur arc
#   tie_stop_keys   => { pos_key => 1, ... }  tie stops arriving at this note
#   tie_start_keys  => { pos_key => 1, ... }  tie starts leaving from this note
#
# "pos_key" is the raw position string with any ^ suffix stripped, used as an
# opaque key to match the tied-to note.  Ties that cross measure boundaries are
# handled correctly because we walk the entire event list before grouping.

sub _annotate_events {
	my ($self, $events) = @_;
	my %ann;

	my $in_slur       = 0;
	my $slur_num      = 0;
	my $last_slur_ev  = undef;
	my $last_slur_num = 0;
	my %pending_tie;   # pos_key => 1 for notes awaiting a tie-stop

	for my $ev (@$events) {
		my $type = $ev->type;
		next unless $type eq 'Note' || $type eq 'Chord' || $type eq 'Rest';

		my $key = "$ev";   # stringified reference, unique per object

		# Tie tracking (not applicable to rests)
		unless ($type eq 'Rest') {
			my @pos_strs = $type eq 'Chord'
				? @{$ev->data->{nwc_positions} // []}
				: ($ev->data->{nwc_pos} // '0');

			for my $ps (@pos_strs) {
				(my $pk = $ps) =~ s/\^\z//;   # strip tie marker to get the key

				if (delete $pending_tie{$pk}) {
					$ann{$key}{tie_stop_keys}{$pk} = 1;
				}
				if ($ps =~ /\^\z/) {
					$ann{$key}{tie_start_keys}{$pk} = 1;
					$pending_tie{$pk} = 1;
				}
			}
		}

		# Slur tracking (not applicable to rests — rests are inside slur spans
		# but don't carry the arc endpoint markers)
		next if $type eq 'Rest';

		my $has_slur = any { $_ eq 'Slur' } @{$ev->data->{articulations} // []};

		if ($has_slur) {
			unless ($in_slur) {
				$slur_num = ($slur_num % $MAX_SLUR_NUMBER) + 1;
				$ann{$key}{slur_start} = $slur_num;
				$in_slur = 1;
			}
			# Rolling assignment: only the last slurred note's key matters for
			# slur_stop; intermediate dead-stores are intentional.
			$last_slur_ev  = $key;
			$last_slur_num = $slur_num;
		} else {
			if ($in_slur) {
				$ann{$last_slur_ev}{slur_stop} = $last_slur_num;
				$in_slur      = 0;
				$last_slur_ev = undef;
			}
		}
	}

	# Close any slur still open at the end of the staff
	$ann{$last_slur_ev}{slur_stop} = $last_slur_num if $in_slur && defined $last_slur_ev;

	return \%ann;
}

# Associate each Lyric event with the immediately preceding Note or Chord event.
# Lyric events in NWCTXT always follow the note they annotate.
sub _annotate_lyrics {
	my ($self, $events, $ann) = @_;
	$ann //= {};

	my $last_note_key;
	for my $ev (@$events) {
		my $type = $ev->type;
		if ($type eq 'Note' || $type eq 'Chord') {
			$last_note_key = "$ev";
		} elsif ($type eq 'Lyric' && defined $last_note_key) {
			my $d = $ev->data // {};
			push @{ $ann->{$last_note_key}{lyrics} }, {
				text     => $d->{text}     // '',
				verse    => $d->{verse}    // 1,
				syllabic => $d->{syllabic} // 'single',
			};
		}
	}
	return $ann;
}

# Annotate wedge (hairpin) start/stop transitions into an existing %$ann hash.
# NWC stores hairpins as Opts:Crescendo / Opts:Diminuendo on each note/rest/chord
# under the arc, NOT as standalone DynVariance records.
# Sets wedge_start => 'Crescendo'|'Diminuendo' on the first event of each arc,
# and wedge_stop_after => 1 on the last event of each arc.
sub _annotate_wedges {
	my ($self, $events, $ann) = @_;
	$ann //= {};

	my $wedge_now      = undef;   # 'Crescendo' | 'Diminuendo' | undef
	my $prev_wedge_key = undef;   # stringified ref of last event under the arc

	for my $ev (@$events) {
		my $type = $ev->type;
		next unless $type eq 'Note' || $type eq 'Rest' || $type eq 'Chord';

		my $key     = "$ev";
		my $opts    = $ev->data->{opts} // {};
		my $ev_wedge = $opts->{Crescendo}  ? 'Crescendo'
		             : $opts->{Diminuendo} ? 'Diminuendo'
		             : undef;

		if (defined $wedge_now && (!defined $ev_wedge || $ev_wedge ne $wedge_now)) {
			$ann->{$prev_wedge_key}{wedge_stop_after} = 1 if defined $prev_wedge_key;
			$wedge_now = undef;
		}
		if (!defined $wedge_now && defined $ev_wedge) {
			$ann->{$key}{wedge_start} = $ev_wedge;
			$wedge_now = $ev_wedge;
		}

		$prev_wedge_key = defined $ev_wedge ? $key : undef;
	}

	# Close any arc still open at end of staff
	$ann->{$prev_wedge_key}{wedge_stop_after} = 1
		if defined $wedge_now && defined $prev_wedge_key;

	return $ann;
}

# ---------------------------------------------------------------------------
# Private: note / rest / chord XML emission
# ---------------------------------------------------------------------------

sub _emit_note_event {
	my ($self, $event, $clef, $key_fifths, $divisions, $pad, $is_chord_member, $ev_ann, $bar_accidentals) = @_;
	$ev_ann          //= {};
	$bar_accidentals //= {};
	my $d   = $event->data;
	my @out;
	my $i   = $self->{_indent};

	my $pitch = $self->_pos_to_pitch($d->{nwc_pos} // '0', $clef, $key_fifths);

	# Accidentals carry through the bar: once a pitch class is altered in a measure,
	# all subsequent notes at the same step+octave inherit that alteration.
	my $pitch_key = $pitch->{step} . $pitch->{octave};
	if (defined $pitch->{accidental}) {
		$bar_accidentals->{$pitch_key} = $pitch->{alter};
	} elsif (exists $bar_accidentals->{$pitch_key}) {
		$pitch->{alter} = $bar_accidentals->{$pitch_key};
	}
	my $ticks = _rational_to_ticks($event->duration, $divisions);
	my $type  = $NWC_TYPE_MAP{ $d->{base_dur} // '4th' } // 'quarter';

	# Tie flags for this specific position key
	(my $pk = $d->{nwc_pos} // '0') =~ s/\^\z//;
	my $tie_stop  = ($ev_ann->{tie_stop_keys}  // {})->{$pk};
	my $tie_start = ($ev_ann->{tie_start_keys} // {})->{$pk};

	# Slur flags: only the first note of a chord carries the arc endpoints
	my $slur_start = !$is_chord_member && $ev_ann->{slur_start};
	my $slur_stop  = !$is_chord_member && $ev_ann->{slur_stop};

	push @out, "${pad}<note>";
	push @out, "${pad}${i}<chord/>" if $is_chord_member;
	push @out, "${pad}${i}<grace/>" if $d->{is_grace};
	push @out, "${pad}${i}<pitch>";
	push @out, "${pad}${i}${i}<step>$pitch->{step}</step>";
	push @out, "${pad}${i}${i}<alter>$pitch->{alter}</alter>" if $pitch->{alter};
	push @out, "${pad}${i}${i}<octave>$pitch->{octave}</octave>";
	push @out, "${pad}${i}</pitch>";
	unless ($d->{is_grace}) {
		push @out, "${pad}${i}<duration>$ticks</duration>";
		# <tie> elements come after <duration> and before <voice> per MusicXML schema
		push @out, "${pad}${i}<tie type=\"stop\"/>"  if $tie_stop;
		push @out, "${pad}${i}<tie type=\"start\"/>" if $tie_start;
	}
	push @out, "${pad}${i}<voice>1</voice>";
	push @out, "${pad}${i}<type>$type</type>";
	push @out, "${pad}${i}<dot/>" for 1 .. ($d->{dots} // 0);
	push @out, "${pad}${i}<accidental>$pitch->{accidental}</accidental>"
		if $pitch->{accidental};

	# <notations> block
	my @nots;
	push @nots, "${pad}${i}${i}<tied type=\"stop\"/>"               if $tie_stop;
	push @nots, "${pad}${i}${i}<tied type=\"start\"/>"              if $tie_start;
	push @nots, "${pad}${i}${i}<slur number=\"$slur_stop\" type=\"stop\"/>"   if $slur_stop;
	push @nots, "${pad}${i}${i}<slur number=\"$slur_start\" type=\"start\"/>" if $slur_start;

	# Articulations: only on the first note of a chord (is_chord_member is false)
	my @artic_tokens = !$is_chord_member
		? grep { $_ ne 'Slur' } @{ $d->{articulations} // [] }
		: ();
	if (@artic_tokens) {
		my (@artic_els, @ornament_els, @direct_els);
		for my $tok (@artic_tokens) {
			my $map = $ARTICULATION_MAP{$tok};
			if (!defined $map) {
				carp _fmt_msg('warn_unsupported_art', $tok);
				next;
			}
			if    ($map->{group} eq 'articulations') { push @artic_els,   $map->{element} }
			elsif ($map->{group} eq 'ornaments')     { push @ornament_els, $map->{element} }
			else                                     { push @direct_els,   $map->{element} }
		}
		if (@artic_els) {
			push @nots, "${pad}${i}${i}<articulations>";
			push @nots, "${pad}${i}${i}${i}<$_/>" for @artic_els;
			push @nots, "${pad}${i}${i}</articulations>";
		}
		if (@ornament_els) {
			push @nots, "${pad}${i}${i}<ornaments>";
			push @nots, "${pad}${i}${i}${i}<$_/>" for @ornament_els;
			push @nots, "${pad}${i}${i}</ornaments>";
		}
		push @nots, "${pad}${i}${i}<$_/>" for @direct_els;
	}

	if (@nots) {
		push @out, "${pad}${i}<notations>";
		push @out, @nots;
		push @out, "${pad}${i}</notations>";
	}

	# Lyrics: only on the first note of a chord (is_chord_member is false).
	unless ($is_chord_member) {
		for my $lyric (@{ $ev_ann->{lyrics} // [] }) {
			my $num      = $lyric->{verse}    // 1;
			my $syllabic = $lyric->{syllabic} // 'single';
			my $text     = _xml_escape($lyric->{text} // '');
			push @out, "${pad}${i}<lyric number=\"$num\">";
			push @out, "${pad}${i}${i}<syllabic>$syllabic</syllabic>";
			push @out, "${pad}${i}${i}<text>$text</text>";
			push @out, "${pad}${i}</lyric>";
		}
	}

	push @out, "${pad}</note>";
	return @out;
}

sub _emit_rest_event {
	my ($self, $event, $divisions, $pad, $ev_ann) = @_;
	$ev_ann //= {};
	my $d   = $event->data;
	my @out;
	my $i   = $self->{_indent};

	my $ticks = _rational_to_ticks($event->duration, $divisions);
	my $type  = $NWC_TYPE_MAP{ $d->{base_dur} // '4th' } // 'quarter';

	push @out, "${pad}<note>";
	push @out, "${pad}${i}<rest/>";
	push @out, "${pad}${i}<duration>$ticks</duration>";
	push @out, "${pad}${i}<voice>1</voice>";
	push @out, "${pad}${i}<type>$type</type>";
	push @out, "${pad}${i}<dot/>" for 1 .. ($d->{dots} // 0);
	push @out, "${pad}</note>";
	return @out;
}

sub _emit_chord_event {
	my ($self, $event, $clef, $key_fifths, $divisions, $pad, $ev_ann, $bar_accidentals) = @_;
	$ev_ann          //= {};
	$bar_accidentals //= {};
	my $d     = $event->data;
	my @out;

	my $positions = $d->{nwc_positions} // ['0'];
	my $first     = 1;

	for my $pos_str (@$positions) {
		# Build a per-position annotation that inherits slur flags (first note only)
		# and picks the tie flags for this specific position key.
		(my $pk = $pos_str) =~ s/\^\z//;
		my %pos_ann = (
			tie_stop_keys  => { $pk => ($ev_ann->{tie_stop_keys}  // {})->{$pk} // 0 },
			tie_start_keys => { $pk => ($ev_ann->{tie_start_keys} // {})->{$pk} // 0 },
			($first ? (
				slur_start => $ev_ann->{slur_start},
				slur_stop  => $ev_ann->{slur_stop},
				lyrics     => $ev_ann->{lyrics},
			) : ()),
		);
		push @out, $self->_emit_note_event(
			_chord_note_event($event, $pos_str),
			$clef, $key_fifths, $divisions, $pad, !$first, \%pos_ann, $bar_accidentals
		);
		$first = 0;
	}
	return @out;
}

# Build a synthetic Note event for one pitch member of a Chord.
# Uses Event->new so that validation, rational reduction and the
# public accessor contract are all preserved.
sub _chord_note_event {
	my ($chord_event, $pos_str) = @_;
	my $d = $chord_event->data;
	return Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => $chord_event->duration,
		data     => {
			nwc_pos       => $pos_str,
			base_dur      => $d->{base_dur},
			dots          => $d->{dots} // 0,
			articulations => $d->{articulations} // [],
			is_grace      => $d->{is_grace},
		},
	);
}

# ---------------------------------------------------------------------------
# Private: pitch conversion
# ---------------------------------------------------------------------------

# Convert an NWC position string (e.g. "#-6", "b3", "-9^") to a MusicXML
# pitch descriptor { step, octave, alter, accidental }.
#
# Position 0 = middle line (3rd from bottom) of the staff (clef-specific).
# Negative positions go DOWN the staff; positive positions go UP.
# Formula: diatonic_index = octave*7 + step_index + pos_num
sub _pos_to_pitch {
	my ($self, $pos_str, $clef, $key_fifths) = @_;
	$pos_str    //= '0';
	$clef       //= 'Treble';
	$key_fifths //= 0;

	# Parse: optional accidental prefix + signed integer + optional tie marker
	my ($acc_prefix, $pos_num) = ('', 0);
	if ($pos_str =~ /\A([#bnx]*)(-?\d+)\^?\z/) {
		($acc_prefix, $pos_num) = ($1, $2 + 0);
	}

	my $ref      = $CLEF_REF{$clef} // $CLEF_REF{Treble};
	my $index    = $ref->[1] * 7 + $ref->[0] + $pos_num;

	my $octave   = floor($index / 7);
	my $step_i   = $index - $octave * 7;

	my $step     = $STEP_NAMES[$step_i];
	my $key_alt  = _key_alter_for_step($step_i, $key_fifths);

	# Dispatch: known prefixes from %ACCIDENTAL_MAP; empty/unknown -> key-sig alter.
	my ($alter, $accidental);
	if (my $acc = $ACCIDENTAL_MAP{$acc_prefix}) {
		($alter, $accidental) = @$acc;
	} else {
		$alter      = $key_alt;
		$accidental = undef;
	}

	return { step => $step, octave => $octave, alter => $alter, accidental => $accidental };
}

sub _key_alter_for_step {
	my ($step_i, $key_fifths) = @_;
	return 0 unless $key_fifths;

	# P1: $key_fifths != 0 (guarded above). P2: sharp/flat differ only in sign+table.
	my ($sign, $steps) = $key_fifths > 0
		? (1, \@SHARP_STEPS)
		: (-1, \@FLAT_STEPS);
	my $n = abs($key_fifths) > 7 ? 7 : abs($key_fifths);
	for my $k (0 .. $n - 1) {
		return $sign if $steps->[$k] == $step_i;
	}
	return 0;
}

sub _rational_to_ticks {
	my ($rational, $divisions) = @_;
	return int($rational->[0] * $divisions / $rational->[1] + 0.5);
}

sub _emit_tempo {
	my ($self, $bpm, $base, $pad) = @_;
	my $i = $self->{_indent};
	$bpm  //= 120;
	$base //= 'Quarter';

	my $map       = $TEMPO_BASE_MAP{$base} // $TEMPO_BASE_MAP{Quarter};
	my $unit      = $map->{unit};
	my $dot       = $map->{dot};
	my $sound_bpm = int($bpm * $map->{factor} + 0.5);

	my @out;
	push @out, "${pad}<direction placement=\"above\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<metronome parentheses=\"no\">";
	push @out, "${pad}${i}${i}${i}<beat-unit>$unit</beat-unit>";
	push @out, "${pad}${i}${i}${i}<beat-unit-dot/>" if $dot;
	push @out, "${pad}${i}${i}${i}<per-minute>$bpm</per-minute>";
	push @out, "${pad}${i}${i}</metronome>";
	push @out, "${pad}${i}</direction-type>";
	push @out, "${pad}${i}<sound tempo=\"$sound_bpm\"/>";
	push @out, "${pad}</direction>";
	return @out;
}

sub _emit_dynamic {
	my ($self, $marking, $placement, $pad) = @_;
	my $i = $self->{_indent};
	$marking   //= '';
	$placement //= '';

	unless (exists $DYNAMIC_MAP{$marking}) {
		carp _fmt_msg('warn_unknown_dynamic', $marking) if $marking ne '';
		return ();
	}

	my $place = (lc($placement) eq 'above') ? 'above' : 'below';
	my @out;
	push @out, "${pad}<direction placement=\"$place\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<dynamics>";
	push @out, "${pad}${i}${i}${i}<$marking/>";
	push @out, "${pad}${i}${i}</dynamics>";
	push @out, "${pad}${i}</direction-type>";
	my $dyn_vel = $self->{_dyn_vel};
	if (defined $dyn_vel && defined $dyn_vel->{$marking}) {
		my $pct = int($dyn_vel->{$marking} * 100 / 127 + 0.5);
		push @out, "${pad}${i}<sound dynamics=\"$pct\"/>";
	}
	push @out, "${pad}</direction>";
	return @out;
}

# Map NWC DynVariance style -> MusicXML wedge type
Readonly::Hash my %WEDGE_MAP => (
	Crescendo  => 'crescendo',
	Diminuendo => 'diminuendo',
	crescOff   => 'stop',
);

sub _emit_wedge {
	my ($self, $style, $placement, $pad) = @_;
	my $i = $self->{_indent};
	$style     //= '';
	$placement //= '';

	my $wedge_type = $WEDGE_MAP{$style};
	return () unless defined $wedge_type;

	my $place = (lc($placement) eq 'above') ? 'above' : 'below';
	my @out;
	push @out, "${pad}<direction placement=\"$place\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<wedge type=\"$wedge_type\" number=\"1\"/>";
	push @out, "${pad}${i}</direction-type>";
	push @out, "${pad}</direction>";
	return @out;
}

Readonly::Hash my %TEMPO_VARIANCE_TEXT => (
	Accelerando      => 'accel.',
	Ritardando       => 'rit.',
	Rallentando      => 'rall.',
	RitardandoToTempo => 'a tempo',
	Stringendo       => 'string.',
	Breath           => "\x{2019}",   # right single quotation mark used as breath comma
	Caesura          => '//',
);

sub _emit_tempo_variance {
	my ($self, $style, $placement, $pad) = @_;
	$style     //= '';
	$placement //= 'above';
	my $i = $self->{_indent};

	my $text = _xml_escape($TEMPO_VARIANCE_TEXT{$style} // $style);
	return () unless length $text;

	my $place = (lc($placement) eq 'above') ? 'above' : 'below';
	my @out;
	push @out, "${pad}<direction placement=\"$place\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<words font-style=\"italic\">$text</words>";
	push @out, "${pad}${i}</direction-type>";
	push @out, "${pad}</direction>";
	return @out;
}

sub _emit_text_direction {
	my ($self, $text, $placement, $pad) = @_;
	$text      //= '';
	$placement //= '';
	return () unless length $text;
	my $i     = $self->{_indent};
	my $place = (lc($placement) eq 'above') ? 'above' : 'below';
	my @out;
	push @out, "${pad}<direction placement=\"$place\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<words>" . _xml_escape($text) . "</words>";
	push @out, "${pad}${i}</direction-type>";
	push @out, "${pad}</direction>";
	return @out;
}

sub _emit_flow_control {
	my ($self, $directive, $pad) = @_;
	$directive //= '';
	my $map = $FLOW_CONTROL_MAP{$directive};
	return () unless defined $map;
	my $i = $self->{_indent};
	my @out;
	push @out, "${pad}<direction placement=\"above\">";
	if (defined $map->{element}) {
		push @out, "${pad}${i}<direction-type>";
		push @out, "${pad}${i}${i}<$map->{element}/>";
		push @out, "${pad}${i}</direction-type>";
	}
	if (defined $map->{words}) {
		push @out, "${pad}${i}<direction-type>";
		push @out, "${pad}${i}${i}<words font-style=\"italic\">"
			. _xml_escape($map->{words}) . "</words>";
		push @out, "${pad}${i}</direction-type>";
	}
	push @out, "${pad}</direction>";
	return @out;
}

sub _emit_instrument_change {
	my ($self, $name, $patch, $pad) = @_;
	my $i    = $self->{_indent};
	my $prog = ($patch // 0) + 1;
	my $text = $name ? _xml_escape($name) : "Program $prog";
	my @out;
	push @out, "${pad}<direction placement=\"above\">";
	push @out, "${pad}${i}<direction-type>";
	push @out, "${pad}${i}${i}<other-direction>$text</other-direction>";
	push @out, "${pad}${i}</direction-type>";
	push @out, "${pad}</direction>";
	return @out;
}

sub _emit_time_change {
	my ($self, $ts_data, $pad) = @_;
	my @out;
	my $i = $self->{_indent};
	my $beats     = $ts_data->{beats}     // 4;
	my $beat_type = $ts_data->{beat_type} // 4;

	push @out, "${pad}<attributes>";
	push @out, "${pad}${i}<time>";
	push @out, "${pad}${i}${i}<beats>$beats</beats>";
	push @out, "${pad}${i}${i}<beat-type>$beat_type</beat-type>";
	push @out, "${pad}${i}</time>";
	push @out, "${pad}</attributes>";
	return @out;
}

sub _emit_clef_change {
	my ($self, $clef_name, $pad) = @_;
	my @out;
	my $i    = $self->{_indent};
	my $clef = $CLEF_MAP{$clef_name} // $CLEF_MAP{Treble};

	push @out, "${pad}<attributes>";
	push @out, "${pad}${i}<clef>";
	push @out, "${pad}${i}${i}<sign>$clef->{sign}</sign>";
	push @out, "${pad}${i}${i}<line>$clef->{line}</line>"
		if defined $clef->{line};
	push @out, "${pad}${i}</clef>";
	push @out, "${pad}</attributes>";
	return @out;
}

sub _emit_key_change {
	my ($self, $key_data, $pad) = @_;
	my @out;
	my $i      = $self->{_indent};
	my $fifths = $key_data->{fifths} // 0;

	push @out, "${pad}<attributes>";
	push @out, "${pad}${i}<key>";
	push @out, "${pad}${i}${i}<fifths>$fifths</fifths>";
	push @out, "${pad}${i}</key>";
	push @out, "${pad}</attributes>";
	return @out;
}

sub _emit_attributes {
	my ($self, $staff, $divisions, $pad) = @_;
	my @out;
	my $i = $self->{_indent};

	push @out, "${pad}<attributes>";
	push @out, "${pad}${i}<divisions>$divisions</divisions>";

	if (my $key = $staff->initial_key) {
		push @out, "${pad}${i}<key>";
		push @out, "${pad}${i}${i}<fifths>$key->{fifths}</fifths>";
		push @out, "${pad}${i}</key>";
	}

	if (my $ts = $staff->initial_timesig) {
		push @out, "${pad}${i}<time>";
		push @out, "${pad}${i}${i}<beats>$ts->{beats}</beats>";
		push @out, "${pad}${i}${i}<beat-type>$ts->{beat_type}</beat-type>";
		push @out, "${pad}${i}</time>";
	}

	if (my $clef_name = $staff->initial_clef) {
		push @out, "${pad}${i}<clef>";
		my $clef = $CLEF_MAP{$clef_name};
		unless (defined $clef) {
			carp _fmt_msg('warn_unknown_clef', $clef_name);
			$clef = $CLEF_MAP{Treble};
		}
		push @out, "${pad}${i}${i}<sign>$clef->{sign}</sign>";
		push @out, "${pad}${i}${i}<line>$clef->{line}</line>"
			if defined $clef->{line};
		push @out, "${pad}${i}</clef>";
	}

	my $trans = ($staff->instrument // {})->{trans} // 0;
	if ($trans) {
		push @out, "${pad}${i}<transpose>";
		push @out, "${pad}${i}${i}<chromatic>$trans</chromatic>";
		push @out, "${pad}${i}</transpose>";
	}

	push @out, "${pad}</attributes>";
	return @out;
}

# ---------------------------------------------------------------------------
# Private: divisions calculation
# ---------------------------------------------------------------------------

# Strategy: collect the denominator of every rational duration encountered
# across all staves, then compute their LCM.  The divisions value is that LCM,
# guaranteeing exact integer representation for every duration tick count.

sub _calculate_divisions {
	my ($self, $score) = @_;

	my %seen_denoms;
	for my $staff (@{ $score->staves }) {
		for my $event (@{ $staff->events }) {
			my $d = $event->duration->[1];
			$seen_denoms{$d} = 1 if $d > 0;
		}
	}

	return $DEFAULT_DIVISIONS unless %seen_denoms;

	my @denoms = keys %seen_denoms;
	my $lcm = $denoms[0];
	for my $d (@denoms[1..$#denoms]) {
		$lcm = _lcm($lcm, $d);
	}

	return $lcm;
}

# ---------------------------------------------------------------------------
# Private: XML helpers
# ---------------------------------------------------------------------------

# Pre-built table for single-pass XML character escaping.
# Covers the five XML-special ASCII chars; non-ASCII get numeric char refs.
Readonly::Hash my %XML_ESCAPE_MAP => (
	'&'  => '&amp;',
	'<'  => '&lt;',
	'>'  => '&gt;',
	'"'  => '&quot;',
	"'"  => '&apos;',
);

sub _xml_escape {
	my ($s) = @_;
	return '' unless defined $s;
	# Pass 1: strip XML 1.0 illegal control bytes (cannot appear even as &#N;).
	$s =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g;
	# Pass 2: escape XML specials and numeric-ref non-ASCII in a single scan.
	$s =~ s/([&<>"']|[^\x00-\x7F])/$XML_ESCAPE_MAP{$1} \/\/ sprintf "&#%d;", ord($1)/ge;
	return $s;
}

sub _lcm {
	my ($a, $b) = @_;
	return $a / _gcd($a, $b) * $b;
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

The module uses C<croak> for unrecoverable errors and C<carp> for warnings
that allow generation to continue.  All messages are looked up in the
C<%MESSAGES> constant at the top of the file so that the strings are easy to
find and change without searching the whole source.

=head2 Fatal errors (croak)

=over 4

=item C<error_bad_score>

C<generate> was called with an argument that is not a
C<Music::NWC2MusicXML::Score> object.  B<Resolution:> pass the Score object
returned by C<Music::NWC2MusicXML::Parser-E<gt>parse>.

=item C<error_no_staves>

The Score object has zero staves.  Generation cannot proceed without at least
one staff.  B<Resolution:> confirm that the parser found one or more
C<AddStaff> records in the NWCTXT input.

=back

=head2 Warnings (carp)

=over 4

=item C<warn_unknown_clef>

An NWC clef name was encountered that is not present in C<%CLEF_MAP>
(currently: Treble, Bass, Alto, Tenor, Percussion, Tab).
B<Resolution:> Treble is used as a fallback.  The output is playable but
visually incorrect for that staff.

=item C<warn_unknown_dynamic>

A dynamic marking was encountered that is not in C<%DYNAMIC_MAP>
(currently: pppp ppp pp p mp mf f ff fff ffff).
B<Resolution:> the direction element is omitted; the surrounding music is
unaffected.

=item C<warn_unsupported_art>

An articulation token from the NWC C<Dur:> field is not present in
C<%ARTICULATION_MAP>.  B<Resolution:> the mark is omitted from that note;
the note itself is still emitted correctly.

=item C<warn_approx_bar>

A barline style has no direct MusicXML equivalent.
B<Resolution:> a regular barline is used.

=back

=head1 LIMITATIONS

=over 4

=item *

Tuplet C<< <time-modification> >> and C<< <tuplet> >> notation elements are
not yet emitted.  Tuplet durations are stored correctly as rational numbers
in the Score, so the audio timing is right, but the printed notation will
show normal note values rather than tuplet brackets.

=item *

Multi-voice staves (two melodic lines on one staff) assign all events to
MusicXML voice 1.  True voice splitting -- two simultaneous streams with
independent stems -- is deferred to a future release.

=item *

Slur numbering: all slurs use number 1.  If more than one slur arc is open
simultaneously (which is rare but legal in NWC), the overlapping slurs will
share the same number and the output will be invalid.  The constant
C<$MAX_SLUR_NUMBER> documents the intended limit.

=item *

Lyric text (C<Lyric> events) is not yet serialised.  The events are parsed
and stored in the Score but no C<< <lyric> >> elements appear in the output.

=item *

Flow-control directives (Coda, Segno, DaCapo, Volta brackets, etc.) are
stored as C<FlowControl> events by the parser but produce no MusicXML output.

=item *

Page dimensions are always assumed to be A4 (210 x 297 mm).  NWC supports
custom page sizes through C<PgSetup> fields that are not yet read by the
parser.

=item *

Only uniform margins are supported.  NWC allows different left, right, top,
and bottom margins, and also supports mirrored margins for left/right pages.
The generator uses only the left margin value and applies it to all four sides.

=back

=head1 AUTHOR

Nigel Horne C<< <nigel.horne@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Copyright (C) 2025 Nigel Horne.

=head1 FORMAL SPECIFICATION

This section uses Z-notation-inspired schemas to describe the state
transformations performed by the key methods.  The notation is informal;
its purpose is to make the invariants and pre/post-conditions precise enough
for future verification or reimplementation.

Mathematical sets used below:

    Score    -- the internal score object type
    Staff    -- a single staff within a Score
    Event    -- a single musical or structural event
    XML      -- a well-formed XML document string (7-bit ASCII)
    Tenths   -- a non-negative real number representing a MusicXML tenths value
    Q+       -- the set of non-negative rational numbers
    Z        -- the set of integers

=head2 new

    GeneratorInit
    ___________________________
    indent?      : String
    diagnostics? : Diagnostics
    ___________________________
    gen!         : MusicXMLGenerator

    Pre:  indent? in String   (any string, default '  ')
    Post: gen!._indent  = indent? | '  '
          gen!._diagnostics = diagnostics? | undef
          No I/O side effects.

=head2 generate

    Generate
    ___________________________
    gen        : MusicXMLGenerator
    score      : Score
    ___________________________
    xml!       : XML

    Pre:  score.staff_count > 0
    Pre:  score.isa('Music::NWC2MusicXML::Score')

    Let D = lcm { ev.duration.denominator | ev in events(score) }
    Let L = compute_page_layout(score.page_setup)

    Post: xml! is a well-formed MusicXML 4.0 document string
    Post: xml! contains exactly one <defaults> block with
              page_height = 297.0 * TENTHS_PER_MM   (A4)
              page_width  = 210.0 * TENTHS_PER_MM
              margin      = score.page_setup.Left * 10 * TENTHS_PER_MM
                            | DEFAULT_MARGIN_CM * 10 * TENTHS_PER_MM
    Post: xml! contains one <score-part> per staff in score order
    Post: xml! contains one <part> per staff
    Post: for every note event ev in score,
              tick_count(ev) = round(ev.duration[0] * D / ev.duration[1])
          -- no duration is lost or rounded by more than 0.5 ticks

=head2 _annotate_events

    AnnotateSlursTies
    ___________________________
    events : seq Event
    ___________________________
    ann!   : Map(EventRef -> Annotation)

    Let sounding = { ev in events | ev.type in {Note, Rest, Chord} }

    Post: forall ev in sounding,
              ev.data.nwc_pos ends with '^'
              => ann!(ev).tie_start_keys contains stripped_key(ev.data.nwc_pos)
    Post: every tie_start has a matching tie_stop on the next sounding event
          with the same stripped position key (or the arc is left open at
          end-of-staff)
    Post: slur_start is set on the first event of each uninterrupted run of
          events carrying the 'Slur' articulation token
    Post: slur_stop  is set on the last event of each such run
    Post: Rest events are included in slur spans but carry neither
          slur_start nor slur_stop

=head2 _annotate_wedges

    AnnotateWedges
    ___________________________
    events : seq Event
    ann    : Map(EventRef -> Annotation)   -- pre-existing, mutated in place
    ___________________________
    ann!   : Map(EventRef -> Annotation)   -- same map, extended

    Let sounding = { ev in events | ev.type in {Note, Rest, Chord} }

    Post: forall consecutive pairs (e1, e2) in sounding,
              e1.data.opts.Crescendo  and not e2.data.opts.Crescendo
              => ann!(e1).wedge_stop_after = 1

              e1.data.opts.Diminuendo and not e2.data.opts.Diminuendo
              => ann!(e1).wedge_stop_after = 1

              not e1.data.opts.Crescendo  and e2.data.opts.Crescendo
              => ann!(e2).wedge_start = 'Crescendo'

              not e1.data.opts.Diminuendo and e2.data.opts.Diminuendo
              => ann!(e2).wedge_start = 'Diminuendo'

    Post: if the last sounding event carries a hairpin flag,
              ann!(last).wedge_stop_after = 1

=head2 _compute_page_layout

    ComputePageLayout
    ___________________________
    page_setup : HashRef   -- from Score.page_setup (may be empty)
    ___________________________
    layout!    : HashRef

    Let margin_cm = page_setup.Left | DEFAULT_MARGIN_CM   (1.27 cm)
    Let margin_t  = margin_cm * 10 * (TENTHS_PER_SPACE / MM_PER_SPACE)

    Post: layout!.page_height = 297.0 * (TENTHS_PER_SPACE / MM_PER_SPACE)
    Post: layout!.page_width  = 210.0 * (TENTHS_PER_SPACE / MM_PER_SPACE)
    Post: layout!.margin_t    = margin_t
    Post: layout!.center_x    = layout!.page_width / 2
    Post: layout!.right_x     = layout!.page_width - margin_t
    Post: function is pure (no I/O, no state mutation)

=head2 _pos_to_pitch

    PosToPitch
    ___________________________
    pos_str    : String    -- NWC position string, e.g. '#-6', 'b3', '-9^'
    clef       : String    -- NWC clef name, e.g. 'Treble', 'Bass'
    key_fifths : Z         -- circle-of-fifths integer (-7 .. 7)
    ___________________________
    pitch!     : HashRef { step, octave, alter, accidental? }

    Let (acc_prefix, pos_num) = parse(pos_str)
    Let (ref_oct, ref_step)   = CLEF_REF[clef]
    Let index  = ref_oct * 7 + ref_step + pos_num
    Let octave = floor(index / 7)
    Let step_i = index - octave * 7               -- in 0..6
    Let step   = STEP_NAMES[step_i]               -- in {C,D,E,F,G,A,B}

    Post: pitch!.step   = step
    Post: pitch!.octave = octave
    Post: acc_prefix = ''  => pitch!.alter = key_alter_for_step(step_i, key_fifths)
                               pitch!.accidental = undef
          acc_prefix = '#'  => pitch!.alter = 1,   pitch!.accidental = 'sharp'
          acc_prefix = 'b'  => pitch!.alter = -1,  pitch!.accidental = 'flat'
          acc_prefix = 'n'  => pitch!.alter = 0,   pitch!.accidental = 'natural'
          acc_prefix = 'x'
       or acc_prefix = '##' => pitch!.alter = 2,   pitch!.accidental = 'double-sharp'
          acc_prefix = 'bb' => pitch!.alter = -2,  pitch!.accidental = 'double-flat'

=cut

package Music::NWC2MusicXML;

use strict;
use warnings;
use autodie qw(:all);

our $VERSION = '0.001.0';

use Carp qw(croak carp);
use Readonly;
use File::Spec ();
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use Object::Configure;
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Diagnostics;

# ---------------------------------------------------------------------------
# Exit codes (also exported for use by the CLI script)
# ---------------------------------------------------------------------------
Readonly::Scalar our $EXIT_OK        => 0;
Readonly::Scalar our $EXIT_WARNINGS  => 1;
Readonly::Scalar our $EXIT_BAD_INPUT => 2;
Readonly::Scalar our $EXIT_OUTPUT    => 3;
Readonly::Scalar our $EXIT_INTERNAL  => 4;

# Default output extension for uncompressed MusicXML
Readonly::Scalar my $OUTPUT_EXT => '.musicxml';

# Maximum single-file decompressed size (forwarded to NWC decoder)
Readonly::Scalar my $INPUT_EXT  => '.nwc';

Readonly::Hash my %MESSAGES => (
	error_no_input       => 'No input file or data specified',
	error_no_output      => 'No output path could be determined',
	error_file_not_found => 'Input file not found: %s',
	error_decode         => 'NWC decoding failed for %s: %s',
	error_parse          => 'NWCTXT parsing failed for %s: %s',
	error_generate       => 'MusicXML generation failed for %s: %s',
	error_write          => 'Cannot write output %s: %s',
	error_mkdir          => 'Cannot create output directory %s: %s',
	error_traversal      => 'Path traversal rejected: %s is outside base_dir %s',
	error_internal       => 'Internal error: %s',
	info_converting      => 'Converting: %s -> %s',
	info_done            => 'Done: %s',
	info_skipped         => 'Skipped (output exists, --overwrite not set): %s',
);

=head1 NAME

Music::NWC2MusicXML - Convert NoteWorthy Composer 2 C<.nwc> score files to MusicXML.

=head1 VERSION

0.001.0

=head1 SYNOPSIS

    # Simple conversion
    use Music::NWC2MusicXML;

    my $converter = Music::NWC2MusicXML->new;
    $converter->convert(
        input  => 'Pilgrim.nwc',
        output => 'Pilgrim.musicxml',
    );

    # Batch conversion
    $converter->batch_convert(
        inputs     => [ glob('*.nwc') ],
        output_dir => 'musicxml',
        overwrite  => 1,
    );

=head1 DESCRIPTION

C<Music::NWC2MusicXML> is the top-level facade for the NWC-to-MusicXML conversion
pipeline.  It coordinates three independent stages:

=over 4

=item 1. B<NWC binary decoding> (C<Music::NWC2MusicXML::NWC>) -- reads the C<.nwc>
binary container, verifies the magic signature, decompresses the zlib payload,
and extracts the NWCTXT text representation.

=item 2. B<NWCTXT parsing> (C<Music::NWC2MusicXML::Parser>) -- parses the NWCTXT into
an internal representation (C<Music::NWC2MusicXML::Score>).

=item 3. B<MusicXML generation> (C<Music::NWC2MusicXML::MusicXML>) -- serialises the
internal representation to a well-formed UTF-8 MusicXML document.

=back

Each stage is independently testable.  The facade wires them together,
handles batch processing, and routes all diagnostics through a single
C<Music::NWC2MusicXML::Diagnostics> instance.

=head1 PRESERVATION PRINCIPLE

The guiding principle of the conversion is:

I<Preserve musical meaning rather than graphical appearance.>

Priority order: notes and rhythm > voices > measures > articulations >
dynamics > lyrics > structural markings > instrument info > graphical layout.

=cut

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

=head2 new

Construct a converter.

=head3 Purpose

Creates a configured converter instance that can be reused for multiple
conversions without reconstructing the pipeline components each time.

=head3 Arguments

Named parameters:

=over 4

=item C<log_level>    -- C<quiet>, C<normal> (default), C<verbose>, C<debug>.

=item C<warnings_fh> -- filehandle for warning output (optional; defaults to
STDERR in the C<Diagnostics> object).

=item C<validate>    -- perform extended consistency checks (boolean, default 0).

=back

=head3 Returns

Blessed C<Music::NWC2MusicXML> object.

=head3 Usage Example

    my $c = Music::NWC2MusicXML->new(log_level => 'verbose', validate => 1);

=head3 API SPECIFICATION

=head4 Input

    log_level    : SCALAR  (optional, default 'normal')
    warnings_fh  : (filehandle, optional)
    validate     : SCALAR  (optional, default 0)

=head4 Output

    Music::NWC2MusicXML object

=head3 MESSAGES

None.

=cut

sub new {
	my $class = shift;
	my $input = Params::Get::get_params(undef, \@_) // {};
	my $warnings_fh = delete $input->{warnings_fh};   # must be extracted before validate_strict (no glob type)
	my $args = validate_strict(
		input => $input,
		schema => {
			log_level => { type => 'scalar', optional => 1, default  => 'normal' },
			validate  => { type => 'scalar', optional => 1, default  => 0 },
		},
	);
	croak $@ unless defined $args;

	$args = Object::Configure::configure($class, $args);

	my $diag = Music::NWC2MusicXML::Diagnostics->new(
		level       => $args->{log_level},
		(defined $warnings_fh ? (warnings_fh => $warnings_fh) : ()),
	);

	return bless {
		_diagnostics => $diag,
		_validate    => $args->{validate},
		_decoder     => Music::NWC2MusicXML::NWC->new(diagnostics => $diag),
		_parser      => Music::NWC2MusicXML::Parser->new(diagnostics => $diag),
		_generator   => Music::NWC2MusicXML::MusicXML->new(diagnostics => $diag),
	}, $class;
}

# ---------------------------------------------------------------------------
# Public: convert
# ---------------------------------------------------------------------------

=head2 convert

Convert a single C<.nwc> file to MusicXML.

=head3 Purpose

Main single-file conversion entry point.  Chains decoder -> parser ->
generator, writes the output file, and updates the internal diagnostic counters.

=head3 Arguments

Named parameters:

=over 4

=item C<input>     -- path to the C<.nwc> input file (required).

=item C<output>    -- path for the C<.musicxml> output file (optional).
Defaults to the input path with the extension replaced by C<.musicxml>.

=item C<overwrite> -- if false (default), skip conversion when the output file
already exists.

=back

=head3 Returns

Scalar string -- the output file path if conversion succeeded, or undef on
failure.

=head3 Side Effects

Writes the output file.  Updates diagnostic counters.
Croaks on fatal errors; non-fatal issues are issued as warnings.

=head3 Usage Example

    my $out = $c->convert(input => 'Pilgrim.nwc', overwrite => 1);

=head3 API SPECIFICATION

=head4 Input

    input     : SCALAR (path, required)
    output    : SCALAR (path, optional)
    overwrite : boolean (optional, default false)

=head4 Output

    SCALAR (output path) or undef

=head3 MESSAGES

| Code               | Meaning                              | Resolution                    |
|--------------------|--------------------------------------|-------------------------------|
| error_no_input     | C<input> parameter missing           | Provide input path            |
| error_file_not_found| Input file does not exist           | Check path                    |
| error_decode       | NWC decoding stage failed            | See error detail              |
| error_parse        | NWCTXT parsing stage failed          | See error detail              |
| error_generate     | MusicXML generation failed           | See error detail              |
| error_write        | Cannot write output file             | Check permissions / disk space|

=cut

sub convert {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => {
			input     => { type => 'scalar' },
			output    => { type => 'scalar', optional => 1 },
			overwrite => { type => 'boolean', optional => 1, default  => 0 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $in     = $args->{input};
	my $output = $args->{output} // _default_output($in);
	my $diag   = $self->{_diagnostics};

	croak _fmt_msg('error_file_not_found', $in)
		unless -f $in;

	if (!$args->{overwrite} && -f $output) {
		$diag->verbose(_fmt_msg('info_skipped', $output));
		return $output;
	}

	$diag->count(outcome => 'processed');
	$diag->info(_fmt_msg('info_converting', $in, $output));

	return $self->_single_convert($in, $output);
}

# ---------------------------------------------------------------------------
# Public: batch_convert
# ---------------------------------------------------------------------------

=head2 batch_convert

Convert multiple C<.nwc> files, optionally into a separate output directory.

=head3 Purpose

Processes a list of input files in sequence.  Failures on individual files
are caught and counted; conversion continues with remaining files.
A summary is printed at the end.

=head3 Arguments

Named parameters:

=over 4

=item C<inputs>     -- arrayref of input file paths (required).

=item C<output_dir> -- directory for output files (optional; defaults to each
file's own directory).

=item C<overwrite>  -- overwrite existing output files (boolean, default 0).

=item C<recursive>  -- preserve relative directory structure under
C<output_dir> (boolean, default 0).

=item C<base_dir>   -- base directory stripped when computing relative paths
for recursive mode (optional).

=back

=head3 Returns

Hashref: C<< { processed => N, successful => N, warnings => N, failed => N } >>.

=head3 Side Effects

Writes output files.  Prints a summary to STDERR.
Does not croak on per-file failures.

=head3 Usage Example

    $c->batch_convert(
        inputs     => [ glob('scores/**/*.nwc') ],
        output_dir => 'musicxml',
        recursive  => 1,
        base_dir   => 'scores',
        overwrite  => 1,
    );

=head3 API SPECIFICATION

=head4 Input

    inputs     : ARRAYREF of SCALAR paths (required)
    output_dir : SCALAR (optional)
    overwrite  : SCALAR bool (optional, default 0)
    recursive  : SCALAR bool (optional, default 0)
    base_dir   : SCALAR (optional)

=head4 Output

    HASHREF { processed:int, successful:int, warnings:int, failed:int }

=cut

sub batch_convert {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => {
			inputs     => {
				type => 'arrayref',
				element_type => 'string'
			},
			output_dir => { type => 'string', optional => 1 },
			overwrite  => { type => 'boolean', optional => 1, default  => 0 },
			recursive  => { type => 'boolean', optional => 1, default  => 0 },
			base_dir   => { type => 'string', optional => 1 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $diag = $self->{_diagnostics};
	my @results;
	my %counts = (processed => 0, successful => 0, warnings => 0, failed => 0);

	for my $file (@{ $args->{inputs} }) {
		$counts{processed}++;

		# A per-file failure must not abort the batch.
		# Output-path computation is inside the eval so traversal errors
		# are caught per-file rather than aborting the whole batch.
		my $output;
		my $ok = eval {
			$output = $self->_batch_output_path(
				input      => $file,
				output_dir => $args->{output_dir},
				recursive  => $args->{recursive},
				base_dir   => $args->{base_dir},
			);
			$self->convert(
				input     => $file,
				output    => $output,
				overwrite => $args->{overwrite},
			);
		};

		if ($@ || !defined $ok) {
			$diag->info(_fmt_msg('info_done', "FAILED: $file -- $@")) if $@;
			$diag->count(outcome => 'failed');
			$counts{failed}++;
		} else {
			$diag->count(outcome => 'successful');
			$counts{successful}++;
		}

		push @results, { input => $file, output => $output, ok => !!$ok };
	}

	$counts{warnings} = scalar @{ $diag->warnings };

	$diag->summary;

	return { %counts, results => \@results };
}

=head2 diagnostics

Return the C<Music::NWC2MusicXML::Diagnostics> instance.

=cut

sub diagnostics { return $_[0]->{_diagnostics} }

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _single_convert {
	my ($self, $input, $output) = @_;
	my $diag = $self->{_diagnostics};

	# Stage 1: Decode binary NWC -> NWCTXT
	my $nwctxt = eval { $self->{_decoder}->read($input) };
	if ($@) {
		carp _fmt_msg('error_decode', $input, $@);
		$diag->count(outcome => 'failed');
		return undef;
	}

	# Stage 2: Parse NWCTXT -> IR
	my $score = eval { $self->{_parser}->parse($nwctxt) };
	if ($@) {
		carp _fmt_msg('error_parse', $input, $@);
		$diag->count(outcome => 'failed');
		return undef;
	}

	# Optional: extended validation
	if ($self->{_validate}) {
		my $issues = $score->validate;
		for my $issue (@$issues) {
			carp $issue;
		}
	}

	# Stage 3: Generate MusicXML
	my $xml = eval { $self->{_generator}->generate($score) };
	if ($@) {
		carp _fmt_msg('error_generate', $input, $@);
		$diag->count(outcome => 'failed');
		return undef;
	}

	# Write output
	eval { $self->_write_output($output, $xml, $input) };
	if ($@) {
		carp _fmt_msg('error_write', $output, $@);
		$diag->count(outcome => 'failed');
		return undef;
	}

	$diag->info(_fmt_msg('info_done', $output));
	$diag->count(outcome => 'successful');
	return $output;
}

sub _write_output {
	my ($self, $output, $xml, $source) = @_;

	# Ensure parent directory exists. make_path is idempotent (no error if dir
	# already exists), so no -d pre-check is needed and the TOCTOU race is closed.
	my $dir = dirname($output);
	eval { make_path($dir) };
	croak _fmt_msg('error_mkdir', $dir, $@) if $@;

	open my $fh, '>:encoding(UTF-8)', $output
		or croak _fmt_msg('error_write', $output, $!);
	print $fh $xml;
	close $fh;

	return;
}

sub _default_output {
	my ($input) = @_;
	(my $base = $input) =~ s/\Q$INPUT_EXT\E\z//i;
	return $base . $OUTPUT_EXT;
}

sub _batch_output_path {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => {
			input      => { type => 'scalar' },
			output_dir => { type => 'scalar', optional => 1 },
			recursive  => { type => 'scalar', optional => 1, default  => 0 },
			base_dir   => { type => 'scalar', optional => 1 },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $out_name = basename($args->{input});
	$out_name =~ s/\Q$INPUT_EXT\E\z//i;
	$out_name .= $OUTPUT_EXT;

	unless (defined $args->{output_dir}) {
		return File::Spec->catfile(dirname($args->{input}), $out_name);
	}

	if ($args->{recursive} && defined $args->{base_dir}) {
		# Compute relative path from base_dir to preserve directory structure
		my $rel = File::Spec->abs2rel(dirname($args->{input}), $args->{base_dir});
		# Guard: any '..' component means the input sits outside base_dir;
		# writing there would escape output_dir (path traversal).
		croak _fmt_msg('error_traversal', $args->{input}, $args->{base_dir})
			if grep { $_ eq '..' } File::Spec->splitdir($rel);
		return File::Spec->catfile($args->{output_dir}, $rel, $out_name);
	}

	return File::Spec->catfile($args->{output_dir}, $out_name);
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

| Code                 | Meaning                             | Resolution                        |
|----------------------|-------------------------------------|-----------------------------------|
| error_no_input       | input parameter missing             | Provide input path                |
| error_file_not_found | Input file absent                   | Check path and permissions        |
| error_decode         | NWC decoding stage failed           | See embedded error                |
| error_parse          | NWCTXT parsing stage failed         | See embedded error                |
| error_generate       | MusicXML generation failed          | See embedded error                |
| error_write          | Cannot write output                 | Check disk space and permissions  |
| error_mkdir          | Cannot create output directory      | Check parent directory permissions|

=head1 LIMITATIONS

=over 4

=item * Parallel batch processing is not implemented; files are converted sequentially.

=item * MusicXML validation against the official DTD/XSD is not performed
internally; use an external validator with C<--validate>.

=item * Tuplet time-modification and multi-voice C<RestChord> records are not yet
emitted (Phase 4 items).

=back

=head1 DEPENDENCIES

L<Object::Configure> is used to allow callers to pre-configure converter
defaults at the class level (e.g. C<< Music::NWC2MusicXML->configure(log_level => 'verbose') >>).
This means a consuming application can set defaults once and C<new> will
honour them without repeating the arguments on each call.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Music-NWC2MusicXML/coverage/>

=back

=head1 FORMAL SPECIFICATION

=head2 new

 [ConverterInit]
   log_level   : LogLevel
   validate    : Boolean
   diagnostics : Diagnostics
   nwc_decoder : NWCDecoder
   parser      : Parser
   generator   : Generator

 (placeholder -- populate with Z calculus as implementation matures)

=head2 convert

 [Convert]
   input?  : FileName
   output? : FileName
   ----------
   result! : FileName | Undef

 (placeholder)

=head2 batchconvert

 [BatchConvert]
   inputs?     : seq FileName
   output_dir? : DirName
   ----------
   summary!    : BatchSummary

 (placeholder)

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

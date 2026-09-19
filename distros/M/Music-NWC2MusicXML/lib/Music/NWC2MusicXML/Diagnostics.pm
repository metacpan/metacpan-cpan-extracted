package Music::NWC2MusicXML::Diagnostics;

use strict;
use warnings;
use autodie qw(:all);

our $VERSION = '0.001.0';

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Params::Get;

# ---------------------------------------------------------------------------
# Log-level constants -- higher value = more output
# ---------------------------------------------------------------------------
Readonly::Scalar my $LOG_QUIET   => 0;
Readonly::Scalar my $LOG_NORMAL  => 1;
Readonly::Scalar my $LOG_VERBOSE => 2;
Readonly::Scalar my $LOG_DEBUG   => 3;

Readonly::Hash my %LOG_LEVEL_MAP => (
	quiet   => $LOG_QUIET,
	normal  => $LOG_NORMAL,
	verbose => $LOG_VERBOSE,
	debug   => $LOG_DEBUG,
);

# ---------------------------------------------------------------------------
# Exit-code constants (mirrored from main spec section 2)
# ---------------------------------------------------------------------------
Readonly::Scalar our $EXIT_OK       => 0;
Readonly::Scalar our $EXIT_WARNINGS => 1;
Readonly::Scalar our $EXIT_BAD_INPUT => 2;
Readonly::Scalar our $EXIT_OUTPUT   => 3;
Readonly::Scalar our $EXIT_INTERNAL => 4;

# ---------------------------------------------------------------------------
# i18n message dictionary -- all user-visible strings live here
# ---------------------------------------------------------------------------
Readonly::Hash my %MESSAGES => (
	error_internal       => 'Internal error: %s',
	error_open_warn_file => 'Cannot open warnings file %s for writing: %s',
	warn_unsupported_obj => '[%s] Staff %s at %s: unsupported NWC object %s (%s)',
	warn_approx_feature  => '[%s] Staff %s at %s: %s approximated as %s',
	warn_no_equivalent   => '[%s] Staff %s at %s: %s has no MusicXML equivalent -- preserved in diagnostics',
	info_file_start      => 'Converting: %s',
	info_file_done       => 'Done: %s -> %s',
	info_file_failed     => 'FAILED: %s (%s)',
	info_summary         => 'Files processed: %d  Successful: %d  Warnings: %d  Failed: %d',
	debug_decode_step    => '[DEBUG] NWC decode: %s',
	debug_parse_step     => '[DEBUG] Parser: %s',
	debug_gen_step       => '[DEBUG] MusicXML gen: %s',
);

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

=head1 NAME

Music::NWC2MusicXML::Diagnostics - Warning collection, logging, and reporting for
the Music::NWC2MusicXML conversion pipeline.

=head1 VERSION

0.001.0

=head1 SYNOPSIS

    use Music::NWC2MusicXML::Diagnostics;

    my $diag = Music::NWC2MusicXML::Diagnostics->new(
        level        => 'verbose',
        warnings_fh  => \*STDERR,
    );

    $diag->warn_unsupported(
        file   => 'Pilgrim.nwc',
        staff  => 'Staff 1',
        pos    => '4:2',
        object => 'UserTool',
        reason => 'No MusicXML equivalent',
    );

    $diag->summary;

=head1 DESCRIPTION

Centralises all diagnostic output for the Music::NWC2MusicXML pipeline.  No
module should print warnings or debug traces directly; instead each module
receives a C<Diagnostics> instance and routes output through it.

Supports four severity levels: quiet, normal (default), verbose, debug.
Warnings can be written to an optional file handle (C<--warnings FILE>).
A summary count (processed / successful / warnings / failed) is maintained
and can be printed at batch completion.

=cut

=head2 new

Construct a Diagnostics instance.

=head3 Arguments

Named parameters:

=over 4

=item C<level> -- log verbosity (optional, default C<'normal'>).

=item C<warnings_fh> -- writable filehandle for per-warning output (optional).

=back

=head3 Returns

Blessed C<Music::NWC2MusicXML::Diagnostics> object.

=head3 API SPECIFICATION

=head4 Input

    level        : SCALAR (optional, default 'normal')
                     -- Valid domain (4 values only, case-sensitive):
                     --   'quiet', 'normal', 'verbose', 'debug'
                     -- Invalid: undef, '' (empty), wrong-case ('QUIET', 'Normal'),
                     --   numeric (0, 1, 2, 3), or any other string -> croak
                     --   error_internal 'Unknown log level: ...'
    warnings_fh  : filehandle (optional)
                     -- Valid: any writable filehandle, or undef/absent (no file output)
                     -- The caller retains ownership; this module never closes it

=head4 Output

    Music::NWC2MusicXML::Diagnostics object

=cut

sub new {
	my ($class, %input) = @_;
	my $warnings_fh = delete $input{warnings_fh};   # glob refs can't be typed
	my $args = validate_strict(
		schema => {
			level => { type => 'scalar', optional => 1, default => 'normal' },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $level_key = $args->{level} // '';
	croak _fmt_msg('error_internal', 'Unknown log level: ' . ($level_key || '(undef)'))
		unless exists $LOG_LEVEL_MAP{$level_key};

	my $self = bless {
		_level       => $LOG_LEVEL_MAP{$level_key},
		_warnings_fh => $warnings_fh,
		_warnings    => [],
		_counts      => { processed => 0, successful => 0, warnings => 0, failed => 0 },
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Public: logging methods
# ---------------------------------------------------------------------------

=head2 info

Log an informational message (suppressed at C<quiet> level).

=head3 Purpose

Emit progress / status information to STDERR.

=head3 Arguments

=over 4

=item C<message> -- the text to emit.

=back

=head3 Returns

C<$self> (for chaining).

=head3 API SPECIFICATION

=head4 Input

    message : SCALAR (required)

=head4 Output

    $self (Music::NWC2MusicXML::Diagnostics)

=head3 FORMAL SPECIFICATION

 [DiagInfo]
   DiagInfo == message : String

 (placeholder -- populate with Z calculus as implementation matures)

=cut

sub info {
	my ($self, $message) = @_;
	return $self if $self->{_level} < $LOG_NORMAL;
	print STDERR $message, "\n";
	return $self;
}

=head2 verbose

Log a verbose message (emitted only at C<verbose> or C<debug> level).

=head3 Purpose

Emit per-file detail that is too chatty for normal output but useful when
diagnosing conversion issues.

=head3 Arguments

=over 4

=item C<message> -- the text to emit.

=back

=head3 Returns

C<$self>.

=head3 API SPECIFICATION

=head4 Input

    message : SCALAR (required)

=head4 Output

    $self (Music::NWC2MusicXML::Diagnostics)

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub verbose {
	my ($self, $message) = @_;
	return $self if $self->{_level} < $LOG_VERBOSE;
	print STDERR $message, "\n";
	return $self;
}

=head2 debug

Log a debug trace (emitted only at C<debug> level).

=head3 Purpose

Emit low-level pipeline tracing for developer use.

=head3 Arguments

=over 4

=item C<message> -- the text to emit.

=back

=head3 Returns

C<$self>.

=head3 API SPECIFICATION

=head4 Input

    message : SCALAR (required)

=head4 Output

    $self (Music::NWC2MusicXML::Diagnostics)

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub debug {
	my ($self, $message) = @_;
	return $self if $self->{_level} < $LOG_DEBUG;
	print STDERR '[DEBUG] ', $message, "\n";
	return $self;
}

=head2 warn_unsupported

Record a warning for an unsupported NWC object.

=head3 Purpose

Called when the parser or generator encounters an NWC object it cannot
represent in MusicXML.  The warning is added to the internal list and, if
a C<warnings_fh> was supplied, written immediately to that handle.

=head3 Arguments

Named parameters (hashref or flat list):

=over 4

=item C<file>   -- input filename (string, required).

=item C<staff>  -- staff name or number (string, required).

=item C<pos>    -- measure:beat position string (string, optional).

=item C<object> -- NWC object type name (string, required).

=item C<reason> -- human-readable reason (string, optional).

=back

=head3 Returns

C<$self>.

=head3 Side Effects

Increments the internal warning counter.  Writes to C<warnings_fh> if set.

=head3 Usage Example

    $diag->warn_unsupported(
        file   => 'Pilgrim.nwc',
        staff  => 'Violin I',
        pos    => '12:1',
        object => 'UserTool',
        reason => 'No MusicXML equivalent',
    );

=head3 API SPECIFICATION

=head4 Input

    file   : SCALAR (required)
    staff  : SCALAR (required)
    pos    : SCALAR (optional, default => '?')
    object : SCALAR (required)
    reason : SCALAR (optional, default => 'unknown')

=head4 Output

    $self (Music::NWC2MusicXML::Diagnostics)

=head3 MESSAGES

| Code                    | Resolution                         |
|-------------------------|------------------------------------|
| warn_unsupported_obj    | NWC object has no MusicXML mapping |

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub warn_unsupported {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => {
			file   => { type => 'scalar' },
			staff  => { type => 'scalar' },
			pos    => { type => 'scalar', optional => 1, default => '?' },
			object => { type => 'scalar' },
			reason => { type => 'scalar', optional => 1, default => 'unknown' },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $msg = _fmt_msg('warn_unsupported_obj',
		$args->{file}, $args->{staff}, $args->{pos}, $args->{object}, $args->{reason});

	$self->_record_warning($msg);
	return $self;
}

=head2 warn_approximate

Record a warning that an NWC feature was approximated.

=head3 Purpose

Called when an NWC feature maps only approximately to a MusicXML construct.

=head3 Arguments

Named parameters: C<file>, C<staff>, C<pos>, C<feature>, C<approximation>.

=head3 Returns

C<$self>.

=head3 API SPECIFICATION

=head4 Input

    file          : SCALAR (required)
    staff         : SCALAR (required)
    pos           : SCALAR (optional)
    feature       : SCALAR (required)
    approximation : SCALAR (required)

=head4 Output

    $self

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub warn_approximate {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => {
			file          => { type => 'scalar' },
			staff         => { type => 'scalar' },
			pos           => { type => 'scalar', optional => 1, default => '?' },
			feature       => { type => 'scalar' },
			approximation => { type => 'scalar' },
		},
		input => \%input,
	);
	croak $@ unless defined $args;

	my $msg = _fmt_msg('warn_approx_feature',
		$args->{file}, $args->{staff}, $args->{pos},
		$args->{feature}, $args->{approximation});

	$self->_record_warning($msg);
	return $self;
}

=head2 count

Update the batch summary counters.

=head3 Purpose

Called by the top-level converter to track per-file outcomes.

=head3 Arguments

Named parameter: C<outcome> -- one of C<processed>, C<successful>,
C<warnings>, C<failed>.

=head3 Returns

C<$self>.

=head3 API SPECIFICATION

=head4 Input

    outcome : SCALAR (required)
                -- Valid domain (4 values only, case-sensitive):
                --   'processed', 'successful', 'warnings', 'failed'
                -- Invalid: undef, '' (empty), wrong-case ('Processed'), any other
                --   string -> croak error_internal 'Unknown counter: ...'

=head4 Output

    $self

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub count {
	my ($self, %input) = @_;
	my $args = validate_strict(
		schema => { outcome => { type => 'scalar' } },
		input  => \%input,
	);
	croak $@ unless defined $args;

	croak _fmt_msg('error_internal', 'Unknown counter: ' . $args->{outcome})
		unless exists $self->{_counts}{ $args->{outcome} };

	$self->{_counts}{ $args->{outcome} }++;
	return $self;
}

=head2 summary

Print the batch processing summary.

=head3 Purpose

Emits the Files processed / Successful / Warnings / Failed summary to STDERR
at the end of a batch run.

=head3 Returns

C<$self>.

=head3 API SPECIFICATION

=head4 Input

    (none)

=head4 Output

    $self

=head3 FORMAL SPECIFICATION

 (placeholder)

=cut

sub summary {
	my ($self) = @_;
	return $self if $self->{_level} < $LOG_NORMAL;
	my $c = $self->{_counts};
	print STDERR _fmt_msg('info_summary',
		$c->{processed}, $c->{successful}, $c->{warnings}, $c->{failed}), "\n";
	return $self;
}

=head2 warnings

Return an arrayref of all collected warning strings.

=head3 Returns

Arrayref of strings.

=head3 API SPECIFICATION

=head4 Input

    (none)

=head4 Output

    arrayref of SCALAR

=cut

sub warnings {
	my ($self) = @_;
	return $self->{_warnings};
}

=head2 has_warnings

Return true if any warnings have been collected.

=cut

sub has_warnings {
	my ($self) = @_;
	return scalar @{ $self->{_warnings} } > 0;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _record_warning {
	my ($self, $msg) = @_;
	push @{ $self->{_warnings} }, $msg;
	$self->{_counts}{warnings}++;
	if (defined $self->{_warnings_fh}) {
		print { $self->{_warnings_fh} } 'WARNING: ', $msg, "\n";
	}
	if ($self->{_level} >= $LOG_NORMAL) {
		print STDERR 'WARNING: ', $msg, "\n";
	}
	return;
}

# Class-level helper; not a method so it can be called before construction.
sub _fmt_msg {
	my ($key, @args) = @_;
	croak "Unknown message key: $key" unless exists $MESSAGES{$key};
	return sprintf $MESSAGES{$key}, @args;
}

1;

__END__

=head1 DIAGNOSTICS

See C<%MESSAGES> hash in source for all message keys and their
C<sprintf>-compatible format strings.

=head1 LIMITATIONS

=over 4

=item * Warning file is opened externally; this module does not open files itself.

=item * Thread safety is not guaranteed.

=back

=head1 AUTHOR

Nigel Horne C<< <nigel.horne@gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

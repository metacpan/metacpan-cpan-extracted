package Music::NWC2MusicXML::NWC;

use strict;
use warnings;
use autodie qw(open close);

our $VERSION = '0.001.0';

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Params::Get;
use Compress::Zlib ();

# ---------------------------------------------------------------------------
# Binary format constants
# ---------------------------------------------------------------------------

# The [NWZ] signature bytes at the start of a binary NWC 2.x file.
# Stored as a Readonly so every comparison in the module uses the same value.
Readonly::Scalar my $NWC_MAGIC        => '[NWZ]';
Readonly::Scalar my $NWC_MAGIC_LEN    => length $NWC_MAGIC;

# The text marker that opens the NWCTXT content inside the decompressed stream.
Readonly::Scalar my $NWCTXT_MARKER    => '!NoteWorthyComposer(';

# Safety limit: reject decompressed payloads larger than this.
# A 50 MB score would be extraordinary; 256 MB signals something is wrong.
Readonly::Scalar my $MAX_DECOMP_BYTES => 256 * 1024 * 1024;

# Minimum length of a plausible NWC binary file.
Readonly::Scalar my $MIN_FILE_BYTES   => $NWC_MAGIC_LEN + 4;

# zlib CMF byte for deflate streams (window size bits 7..4 = 7, CM 3..0 = 8)
Readonly::Scalar my $ZLIB_CMF         => 0x78;

# Valid FLG bytes that satisfy (CMF*256 + FLG) % 31 == 0 for CMF = 0x78
Readonly::Array  my @ZLIB_VALID_FLAGS => (0x01, 0x5E, 0x9C, 0xDA);

Readonly::Hash my %MESSAGES => (
	error_not_a_file       => 'Cannot read file: %s',
	error_not_nwc          => 'Not a valid NWC file (magic not found): %s',
	error_truncated        => 'File appears truncated: %s',
	error_no_zlib_stream   => 'No compressed data stream found in: %s',
	error_decompress_fail  => 'Decompression failed: %s',
	error_decomp_too_large => 'Decompressed data exceeds safety limit (%d bytes): %s',
	error_no_nwctxt_marker => 'NWCTXT marker not found in decompressed data: %s',
	error_bad_utf8         => 'NWCTXT text is not valid UTF-8: %s',
	error_internal         => 'Internal error: %s',
	warn_unknown_version   => 'Unrecognised NWC version %s -- attempting conversion anyway',
);

=head1 NAME

Music::NWC2MusicXML::NWC - Binary NWC container decoder.

=head1 VERSION

0.001.0

=head1 SYNOPSIS

    use Music::NWC2MusicXML::NWC;

    # From a file
    my $nwctxt = Music::NWC2MusicXML::NWC->read('Pilgrim.nwc');

    # From an in-memory buffer (e.g. read from a database blob)
    my $nwctxt = Music::NWC2MusicXML::NWC->decode($binary_data);

    print $nwctxt;   # prints the NWCTXT representation

=head1 DESCRIPTION

Converts a NoteWorthy Composer 2 binary C<.nwc> file into its NWCTXT text
representation.  The NWCTXT string is then passed to
C<Music::NWC2MusicXML::Parser>.

The conversion pipeline implemented here is:

    NWC binary container
          |
          v  (verify magic + locate zlib stream)
    compressed score data
          |
          v  (Compress::Zlib inflate)
    raw decompressed bytes
          |
          v  (locate !NoteWorthyComposer( marker)
    NWCTXT representation (UTF-8 string)

No NoteWorthy Composer installation is required.

=cut

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head2 new

Construct a decoder object.  Optionally binds diagnostic output to a
C<Music::NWC2MusicXML::Diagnostics> instance.

=head3 Arguments

Named parameters:

=over 4

=item C<diagnostics> -- a C<Music::NWC2MusicXML::Diagnostics> instance (optional).

=back

=head3 Returns

Blessed C<Music::NWC2MusicXML::NWC> object.

=head3 API SPECIFICATION

=head4 Input

    diagnostics : Music::NWC2MusicXML::Diagnostics  (optional)

=head4 Output

    Music::NWC2MusicXML::NWC object

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
	}, $class;

	return $self;
}

# ---------------------------------------------------------------------------
# Public: read
# ---------------------------------------------------------------------------

=head2 read

Read a C<.nwc> binary file from disk and return its NWCTXT representation.

Can be called as a class method (C<< Music::NWC2MusicXML::NWC->read($file) >>)
or as an instance method.

=head3 Purpose

Encapsulates file-I/O so that C<decode> can be tested independently with
in-memory data.

=head3 Arguments

=over 4

=item C<$filename> -- path to the C<.nwc> file (required).

=back

=head3 Returns

Scalar string containing the NWCTXT representation (UTF-8).

=head3 Side Effects

Reads from disk.  Croaks on any I/O or format error.

=head3 Usage Example

    my $nwctxt = Music::NWC2MusicXML::NWC->read('Pilgrim.nwc');

=head3 API SPECIFICATION

=head4 Input

    $filename : SCALAR  path (required)
                  -- Valid domain: defined, non-empty string naming a regular,
                  --   readable file in NWC 2.x binary format
                  -- Invalid partitions: undef, '' (empty), directory, non-existent,
                  --   unreadable, or wrong format -> all croak error_not_a_file
                  --   or error_not_nwc / error_truncated depending on failure point

=head4 Output

    SCALAR (UTF-8 string)

=head3 MESSAGES

| Code                | Meaning                             | Resolution                     |
|---------------------|-------------------------------------|--------------------------------|
| error_not_a_file    | File cannot be opened               | Check path and permissions     |
| error_not_nwc       | File does not begin with NWC magic  | Verify file is a real .nwc     |
| error_truncated     | File too short to be valid          | File may be corrupt            |

=cut

sub read {
	my ($proto, $filename) = @_;

	croak _fmt_msg('error_not_a_file', $filename // '(undef)')
		unless defined $filename && length $filename;

	croak _fmt_msg('error_not_a_file', $filename)
		unless -f $filename && -r $filename;

	my $data;
	{
		open my $fh, '<:raw', $filename
			or croak _fmt_msg('error_not_a_file', "$filename: $!");
		local $/;
		$data = <$fh>;
		close $fh;
	}

	# Delegate to decode so tests can bypass file I/O entirely.
	my $self = ref($proto) ? $proto : $proto->new;
	return $self->decode($data, $filename);
}

=head2 decode

Decode a binary NWC payload (already loaded into a scalar) and return its
NWCTXT representation.

Can be called as a class method or instance method.

Separates decompression logic from file I/O; enables unit testing with
in-memory test vectors.

=head3 Arguments

=over 4

=item C<$data>     -- binary scalar containing the full file content (required).

=item C<$filename> -- source filename for diagnostic messages (optional, default C<< <buffer> >>).

=back

=head3 Returns

Scalar string containing the NWCTXT representation (UTF-8).

=head3 Side Effects

None (no I/O).  Croaks on any format or decompression error.

=head3 Usage Example

    my $nwctxt = Music::NWC2MusicXML::NWC->decode($binary_blob);

=head3 API SPECIFICATION

=head4 Input

    $data     : SCALAR (binary, required)
                  -- Valid domain: length >= MIN_FILE_BYTES (9 bytes)
                  --   Minimum: 5-byte magic '[NWZ]' + 4 bytes = 9 bytes (MIN_FILE_BYTES)
                  --   Below min (length 0..8): croaks error_truncated
                  --   At min (length 9) with wrong magic: croaks error_not_nwc
                  --   MAX decompressed size: 268,435,456 bytes (MAX_DECOMP_BYTES = 256 MB)
    $filename : SCALAR (optional, default '<buffer>')
                  -- Any string; used only in diagnostic messages

=head4 Output

    SCALAR (UTF-8 string)

=head3 MESSAGES

| Code                   | Meaning                                 | Resolution                        |
|------------------------|-----------------------------------------|-----------------------------------|
| error_not_nwc          | Magic signature absent                  | Confirm file is an NWC 2.x binary |
| error_truncated        | Data too short                          | File may be truncated             |
| error_no_zlib_stream   | zlib stream not found in binary         | File may be corrupt               |
| error_decompress_fail  | zlib inflation failed                   | Payload is corrupt                |
| error_decomp_too_large | Decompressed size exceeds safety limit  | Reject; may be a zip bomb         |
| error_no_nwctxt_marker | NWCTXT marker absent after decompression| File structure unexpected         |
| error_bad_utf8         | Decompressed text is not valid UTF-8    | NWC file may use a legacy encoding|

=cut

sub decode {
	my ($proto, $data, $filename) = @_;
	$filename //= '<buffer>';

	my $self = ref($proto) ? $proto : $proto->new;

	# Guard: minimum viable length
	croak _fmt_msg('error_truncated', $filename)
		if !defined $data || length($data) < $MIN_FILE_BYTES;

	# Verify NWC magic signature at offset 0
	croak _fmt_msg('error_not_nwc', $filename)
		unless substr($data, 0, $NWC_MAGIC_LEN) eq $NWC_MAGIC;

	$self->_debug("magic verified: $filename");

	# Locate the zlib compressed stream within the binary payload.
	# We scan rather than relying on a fixed offset so that different
	# NWC versions and padding sizes are handled uniformly.
	my $zlib_offset = $self->_find_zlib_offset(\$data, $filename);

	$self->_debug("zlib stream at offset $zlib_offset in $filename");

	# Decompress
	my $raw = $self->_decompress(\$data, $zlib_offset, $filename);

	$self->_debug('decompressed ' . length($raw) . ' bytes from ' . $filename);

	# Locate the NWCTXT marker within the decompressed bytes
	my $marker_pos = index($raw, $NWCTXT_MARKER);
	croak _fmt_msg('error_no_nwctxt_marker', $filename)
		if $marker_pos < 0;

	my $nwctxt = substr($raw, $marker_pos);

	# Validate UTF-8: attempt decode; Perl's utf8 flag approach
	# We do not blindly assume the file is UTF-8; we verify it.
	# If it fails, treat as Latin-1 (a common NWC legacy encoding) and warn.
	if (!utf8::decode($nwctxt)) {
		# Latin-1 fallback: re-encode as UTF-8
		utf8::upgrade($nwctxt);
		carp _fmt_msg('error_bad_utf8', $filename)
			. ' -- assuming Latin-1';
	}

	return $nwctxt;
}

# ---------------------------------------------------------------------------
# Private: _find_zlib_offset
# ---------------------------------------------------------------------------

sub _find_zlib_offset {
	my ($self, $data_ref, $filename) = @_;

	# Strategy: scan the binary for a byte pair (CMF, FLG) that satisfies
	# the zlib header checksum rule: (CMF*256 + FLG) % 31 == 0.
	# We look only for CMF=0x78 (deflate, 32K window) which covers all
	# compression levels produced by NoteWorthy Composer.
	#
	# We start at offset NWC_MAGIC_LEN + 2 because at minimum there must
	# be a two-byte version/header field after the magic.

	my $len  = length $$data_ref;
	my $start = $NWC_MAGIC_LEN;    # zlib stream follows immediately after magic

	for my $i ($start .. $len - 2) {
		my $cmf = ord(substr($$data_ref, $i,     1));
		my $flg = ord(substr($$data_ref, $i + 1, 1));

		next unless $cmf == $ZLIB_CMF;
		next unless ($cmf * 256 + $flg) % 31 == 0;

		return $i;
	}

	croak _fmt_msg('error_no_zlib_stream', $filename);
}

# ---------------------------------------------------------------------------
# Private: _decompress
# ---------------------------------------------------------------------------

sub _decompress {
	my ($self, $data_ref, $offset, $filename) = @_;

	my $compressed = substr($$data_ref, $offset);

	# Compress::Zlib::uncompress handles a complete zlib stream.
	# It returns undef on failure.
	my $raw = Compress::Zlib::uncompress(\$compressed);

	croak _fmt_msg('error_decompress_fail', "zlib error in $filename")
		unless defined $raw;

	croak _fmt_msg('error_decomp_too_large', $MAX_DECOMP_BYTES, $filename)
		if length($raw) > $MAX_DECOMP_BYTES;

	return $raw;
}

# ---------------------------------------------------------------------------
# Private: _debug
# ---------------------------------------------------------------------------

sub _debug {
	my ($self, $msg) = @_;
	return unless defined $self->{_diagnostics};
	$self->{_diagnostics}->debug($msg);
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

| Code                   | Meaning                                | Resolution                        |
|------------------------|----------------------------------------|-----------------------------------|
| error_not_a_file       | Cannot open/read input file            | Check path and permissions        |
| error_not_nwc          | Magic signature absent                 | Confirm file is NWC 2.x           |
| error_truncated        | File too short                         | File may be corrupt or incomplete |
| error_no_zlib_stream   | No valid zlib header found             | Binary may be from unknown version|
| error_decompress_fail  | zlib inflate failed                    | Payload corrupt                   |
| error_decomp_too_large | Decompressed size exceeds 256 MB       | Possible zip-bomb; reject         |
| error_no_nwctxt_marker | NWCTXT marker absent                   | Unexpected binary structure       |
| error_bad_utf8         | Text not valid UTF-8                   | Latin-1 fallback applied          |

=head1 LIMITATIONS

=over 4

=item * Only NWC 2.x binary format (C<[NWZ]> magic) is supported.  NWC 1.x
files use a different structure and will be rejected.

=item * Files larger than 256 MB when decompressed will be rejected for
safety.  Legitimate scores should not approach this limit.

=item * Latin-1 fallback for non-UTF-8 NWCTXT is a best-effort heuristic.

=back

=head1 FORMAL SPECIFICATION

=head2 new

 [NWCDecoderInit]
   diagnostics : Diagnostics

 (placeholder -- populate with Z calculus as implementation matures)

=head2 read

 [ReadFile]
   filename? : FileName
   ----------
   result! : NWCTXT

 (placeholder)

=head2 decode

 [Decode]
   data?     : BinaryData
   filename? : FileName
   ----------
   nwctxt!   : NWCTXT

 (placeholder)

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

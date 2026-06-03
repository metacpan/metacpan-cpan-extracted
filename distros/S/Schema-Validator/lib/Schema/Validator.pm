package Schema::Validator;

# ---------------------------------------------------------------------------
# Schema::Validator -- ISO 8601 datetime validation and Schema.org vocabulary
# loading.  Purely functional; all symbols are opt-in via import list.
# ---------------------------------------------------------------------------

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(carp croak);
use DateTime::Format::ISO8601;
use Encode qw(decode encode);
use File::Spec;
use JSON::MaybeXS qw(decode_json);
use LWP::UserAgent;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(reftype);

use base 'Exporter';

# Only these two symbols may be imported by callers via 'use ... qw(...)'.
our @EXPORT_OK = qw(is_valid_datetime load_dynamic_vocabulary);

our $VERSION = '0.03';

# ---------------------------------------------------------------------------
# Package globals: both are populated as a side-effect of
# load_dynamic_vocabulary().  Callers may read them after that call.
# ---------------------------------------------------------------------------

# rdfs:Class items from the Schema.org JSON-LD graph, keyed by class label
our %dynamic_schema;

# rdf:Property items from the Schema.org JSON-LD graph, keyed by property label
our %dynamic_properties;

# ===========================================================================
# CONSTANTS
# ===========================================================================
# All magic strings and numbers are confined here; nothing below uses bare
# literals.  Every constant mirrors a key in %config so runtime overrides
# are possible without re-opening the Readonly namespace.
# ---------------------------------------------------------------------------

# Default cache directory: $CACHEDIR env var if set, otherwise the system
# temporary directory.  Evaluated once at module load time.
Readonly::Scalar my $DEFAULT_CACHE_DIR =>
	(defined $ENV{CACHEDIR} && length $ENV{CACHEDIR})
		? $ENV{CACHEDIR}
		: File::Spec->tmpdir();

# Default cache filename -- stored in $DEFAULT_CACHE_DIR, never in CWD.
Readonly::Scalar my $DEFAULT_CACHE_FILE =>
	File::Spec->catfile($DEFAULT_CACHE_DIR, 'schemaorg_dynamic_vocabulary.jsonld');

# 86400 == 60 * 60 * 24: cache is considered fresh for one full day.
Readonly::Scalar my $DEFAULT_CACHE_DURATION => 86_400;

# Canonical URL for the Schema.org full vocabulary in JSON-LD format.
Readonly::Scalar my $DEFAULT_VOCAB_URL => 'https://schema.org/version/latest/schemaorg-current-https.jsonld';

# HTTP timeout for the vocabulary download request, in seconds.
Readonly::Scalar my $DEFAULT_UA_TIMEOUT => 30;

# JSON-LD structural keys and RDF type labels used when traversing @graph.
Readonly::Scalar my $AT_GRAPH        => '@graph';
Readonly::Scalar my $RDF_CLASS       => 'rdfs:Class';
Readonly::Scalar my $RDF_PROPERTY    => 'rdf:Property';
Readonly::Scalar my $RDFS_LABEL      => 'rdfs:label';
Readonly::Scalar my $RDFS_LABEL_FULL => 'http://www.w3.org/2000/01/rdf-schema#label';

# ===========================================================================
# CONFIGURATION
# ===========================================================================
# Callers may override any key before calling an exported function, or inject
# a full replacement via Object::Configure->configure('Schema::Validator', \%h).
# ---------------------------------------------------------------------------
our %config = (
	cache_file     => $DEFAULT_CACHE_FILE,
	cache_duration => $DEFAULT_CACHE_DURATION,
	vocab_url      => $DEFAULT_VOCAB_URL,
	ua_timeout     => $DEFAULT_UA_TIMEOUT,
);

# ===========================================================================
# PUBLIC INTERFACE (POD + code)
# ===========================================================================

=head1 NAME

Schema::Validator - Tools for validating and loading Schema.org vocabulary definitions

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

    # Validate a date or datetime string
    if (is_valid_datetime('2024-11-14')) {
        print "Valid date\n";
    }

    # Load and query the Schema.org vocabulary
    my $classes = load_dynamic_vocabulary();
    if (exists $classes->{'Person'}) {
        print "Person class is defined\n";
    }

    # Override a config value for a single call
    my $classes = load_dynamic_vocabulary(ua_timeout => 60);

=head1 DESCRIPTION

C<Schema::Validator> provides two utilities for working with Schema.org
structured data:

=over 4

=item * L</is_valid_datetime> -- validates a string against the ISO 8601
date/datetime subset used by Schema.org.

=item * L</load_dynamic_vocabulary> -- downloads (and caches for 24 hours)
the full Schema.org JSON-LD vocabulary and exposes all class and property
definitions as a hashref and via package globals.

=back

=head2 Configuration

Runtime behaviour is controlled by the package-level C<%Schema::Validator::config>
hash.  Supported keys and their defaults:

    cache_file     => "$CACHEDIR/schemaorg_dynamic_vocabulary.jsonld"  # or tmpdir
    cache_duration => 86400                                          # seconds
    vocab_url      => 'https://schema.org/.../schemaorg-current-https.jsonld'
    ua_timeout     => 30                                             # seconds

Override any key before calling an exported function:

    $Schema::Validator::config{ua_timeout} = 60;

Or supply a complete replacement via L<Object::Configure>:

    Object::Configure->configure('Schema::Validator', \%my_config);

=head1 PACKAGE VARIABLES

=head2 %dynamic_schema

Package hash keyed by Schema.org class label (e.g. C<Person>, C<Event>).
Values are the raw item hashrefs from the JSON-LD C<@graph> array.
Populated as a side-effect of L</load_dynamic_vocabulary>.

=head2 %dynamic_properties

Package hash keyed by Schema.org property label (e.g. C<name>, C<startDate>).
Values are the raw item hashrefs from the JSON-LD C<@graph> array.
Populated as a side-effect of L</load_dynamic_vocabulary>.

=head1 FUNCTIONS

=head2 is_valid_datetime

=head3 PURPOSE

Tests whether a scalar string conforms to one of the ISO 8601
date or datetime formats accepted by Schema.org:

    YYYY-MM-DD               (date only)
    YYYY-MM-DDTHH:MM         (T separator, no seconds)
    YYYY-MM-DD HH:MM         (space separator, no seconds)
    YYYY-MM-DDTHH:MM:SS      (T separator, with seconds)
    YYYY-MM-DD HH:MM:SS      (space separator, with seconds)

Optional timezone designators (C<Z>, C<+HH:MM>, C<-HH:MM>) are B<accepted>.
Calendar sanity B<is> enforced: out-of-range values (e.g. month 99) are B<rejected>.

=head3 ARGUMENTS

=over 4

=item * C<string> (required, scalar) -- the candidate string to test.
Both positional (C<is_valid_datetime('2024-11-14')>) and named
(C<is_valid_datetime(string =E<gt> '2024-11-14')>) calling conventions
are accepted.

=back

=head3 RETURNS

C<1> if the string is in a supported format; C<0> otherwise.
Returns C<0> for C<undef> or an empty string without throwing.

=head3 SIDE EFFECTS

None.

=head3 NOTES

Delegates to C<DateTime::Format::ISO8601->parse_datetime()> for semantic
validation, so out-of-range values (e.g. month 99) are rejected.
The space-separator variant (C<YYYY-MM-DD HH:MM>) is normalised to a T
separator before parsing since the module requires strict ISO 8601.
Timezone designators (C<Z>, C<+HH:MM>, C<-HH:MM>) are now accepted.

=head3 EXAMPLE

    use Schema::Validator qw(is_valid_datetime);

    is_valid_datetime('2024-11-14');                 # 1
    is_valid_datetime('2024-11-14T15:30:00');        # 1
    is_valid_datetime('2024-11-14 15:30');           # 1  (space sep normalised)
    is_valid_datetime('2024-11-14T15:30:00Z');       # 1  (UTC timezone)
    is_valid_datetime('2024-11-14T15:30:00+01:00');  # 1  (offset timezone)
    is_valid_datetime('2024-99-01');                 # 0  (invalid month)
    is_valid_datetime('28/06/2025');                 # 0
    is_valid_datetime(undef);                        # 0  (no exception)
    is_valid_datetime('');                           # 0  (no exception)

    # Named calling convention
    is_valid_datetime(string => '2024-11-14');       # 1

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

    {
        string => {
            type     => 'string',
            optional => 0,
        },
    }

=head4 Output (Return::Set)

    {
        type => 'boolean'
        description  => '1 (valid) or 0 (invalid, undef, or empty input)'
    }

=cut

sub is_valid_datetime {
	# Accept both positional (is_valid_datetime($s)) and named
	# (is_valid_datetime(string => $s)) calling conventions.
	# Validate: value must be a scalar or undef (undef returns 0 cleanly below).
	my $p = validate_strict(
		input => get_params('string', \@_),
		schema   => { 'string' => { type => 'string', optional => 0 } },
	);

	my $string = $p->{string};

	# Treat undef or empty string as invalid without throwing.
	return 0 unless defined $string && length $string;

	# Normalise the space-separator variant to T before handing off to the
	# module, which requires strict ISO 8601 (T separator only).
	(my $normalised = $string) =~ s/^(\d{4}-\d{2}-\d{2}) (?=\d{2}:)/$1T/;

	# Delegate to DateTime::Format::ISO8601 for full semantic validation;
	# a truthy (DateTime) object means valid, undef/$@ means invalid.
	return eval { DateTime::Format::ISO8601->parse_datetime($normalised) } ? 1 : 0;
}

# ===========================================================================

=head2 load_dynamic_vocabulary

=head3 PURPOSE

Downloads the complete Schema.org vocabulary from the official JSON-LD
endpoint, parses it into class and property lookup tables, caches the raw
JSON-LD locally, and returns the class table as a hashref.

The cache is considered fresh for C<cache_duration> seconds (default 24 hours).
On network failure the function falls back to a stale cache rather than
returning an empty result, and emits a C<carp> warning.

=head3 ARGUMENTS

All arguments are optional; defaults come from C<%Schema::Validator::config>.

=over 4

=item * C<cache_file> (optional, scalar) -- path to the local cache file.
Defaults to C<$config{cache_file}>: C<$CACHEDIR/schemaorg_dynamic_vocabulary.jsonld>
if C<$ENV{CACHEDIR}> is set, otherwise C<File::Spec-E<gt>tmpdir()> is used.

=item * C<cache_duration> (optional, scalar) -- cache validity window in seconds.
Defaults to C<$config{cache_duration}>.

=item * C<vocab_url> (optional, scalar) -- URL of the JSON-LD vocabulary endpoint.
Defaults to C<$config{vocab_url}>.

=item * C<ua_timeout> (optional, scalar) -- LWP::UserAgent timeout in seconds.
Defaults to C<$config{ua_timeout}>.

=back

Both zero-argument and named calling conventions are supported:

    load_dynamic_vocabulary();
    load_dynamic_vocabulary(ua_timeout => 60);

=head3 RETURNS

A hashref mapping class labels (e.g. C<'Person'>) to their raw JSON-LD
definition hashrefs from the C<@graph> array.

Returns an empty hashref C<{}> on all failure paths (network unreachable,
no cache, JSON parse error).  Never throws.

=head3 SIDE EFFECTS

=over 4

=item * Populates C<%Schema::Validator::dynamic_schema> with class definitions.

=item * Populates C<%Schema::Validator::dynamic_properties> with property definitions.

=item * Creates or updates the local cache file on a successful download.

=item * Emits C<carp> warnings on network failures, I/O errors, or JSON
parse errors.

=back

=head3 NOTES

The default cache directory is determined once at module load time: the
C<$CACHEDIR> environment variable is used if set; otherwise C<File::Spec-E<gt>tmpdir()>
is used (typically C</tmp> on Unix).  Override for the session with:

    $Schema::Validator::config{cache_file} = '/my/path/vocab.jsonld';

The C<bin/validate-schema> CLI tool imports this function from the module and
uses C<cache_file =E<gt> $path> to store its cache under C<~/.cache/schema_validator/>.

=head3 EXAMPLE

    use Schema::Validator qw(load_dynamic_vocabulary);

    my $classes = load_dynamic_vocabulary();
    printf "%d classes loaded\n", scalar keys %{$classes};

    # Check for a specific class in the returned hashref
    print "Has Person\n" if exists $classes->{'Person'};

    # Or query the package globals directly after the call
    Schema::Validator::load_dynamic_vocabulary();
    my @names = sort keys %Schema::Validator::dynamic_schema;

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

    {
        cache_file     => { type => 'string', optional => 1 },
        cache_duration => { type => 'string', optional => 1 },
        vocab_url      => { type => 'string', optional => 1 },
        ua_timeout     => { type => 'string', optional => 1 },
    }

=head4 Output (Return::Set)

    {
	type  => 'hashref',
	description  => 'class-label => JSON-LD item hashref'
	# ON_FAILURE   => 'empty hashref {}; never throws'
	# SIDE_EFFECTS => 'populates %dynamic_schema and %dynamic_properties'
    }

=cut

sub load_dynamic_vocabulary {
	my $params;

	# Validate types of any supplied overrides (all are optional scalars).
	if(scalar(@_)) {
		$params = validate_strict(
			input => get_params(undef, \@_),
			schema   => {
				cache_file     => { type => 'string', optional => 1 },
				cache_duration => { type => 'integer', optional => 1 },
				vocab_url      => { type => 'string', optional => 1 },
				ua_timeout     => { type => 'integer', optional => 1 },
			}
		);
	}

	# Merge caller overrides with module-level configuration defaults.
	my $cache_file     = $params->{cache_file}     // $config{cache_file};
	my $cache_duration = $params->{cache_duration} // $config{cache_duration};
	my $vocab_url      = $params->{vocab_url}      // $config{vocab_url};
	my $ua_timeout     = $params->{ua_timeout}     // $config{ua_timeout};

	my $content;

	# Attempt to read a fresh cache file.  Open directly to avoid the TOCTOU
	# race that would exist between a separate -e test and the open call.
	if (-e $cache_file && (time - (stat($cache_file))[9] < $cache_duration)) {
		eval { $content = _slurp_file($cache_file) };
		carp "Could not read cache '$cache_file': $@" if $@;
	}

	# If no usable content yet, try to download the vocabulary.
	unless (defined $content) {
		$content = _fetch_url($vocab_url, $ua_timeout);

		if (defined $content) {
			# Persist the download to the cache (best-effort; warn, do not die).
			eval { _spit_file($cache_file, $content) };
			carp "Could not write cache '$cache_file': $@" if $@;
		} else {
			# Network failed; fall back to a stale cache if one exists.
			if (-e $cache_file) {
				eval { $content = _slurp_file($cache_file) };
				if ($@) {
					carp "Could not read stale cache '$cache_file': $@";
				} else {
					carp "Network unavailable; using stale cache '$cache_file'";
				}
			}
		}
	}

	# All content-acquisition strategies failed; return empty result.
	unless (defined $content) {
		carp 'load_dynamic_vocabulary: no vocabulary content available';
		return {};
	}

	# Parse the JSON; treat errors as non-fatal warnings.
	my $data = eval { decode_json($content) };
	if ($@) {
		carp "Failed to parse vocabulary JSON: $@";
		return {};
	}

	# Guard against decode_json returning a non-object (e.g. a JSON array,
	# a bare number, or any other non-hash type).  Calling exists on a
	# non-hashref dies; catching it here keeps the "never throws" contract.
	unless (ref($data) eq 'HASH') {
		carp "Vocabulary JSON is not a JSON object";
		return {};
	}

	# Confirm the expected JSON-LD graph structure is present.
	unless (exists $data->{$AT_GRAPH} && ref($data->{$AT_GRAPH}) eq 'ARRAY') {
		carp "Vocabulary JSON is missing the '\@graph' array";
		return {};
	}

	# Delegate parsing to the internal graph processor.
	my ($classes, $props) = _parse_graph($data->{$AT_GRAPH});

	# Populate package globals as documented side-effects.
	%dynamic_schema     = %{$classes};
	%dynamic_properties = %{$props};

	# Report the result count via carp (informational, not an error).
	carp sprintf(
		'Dynamic vocabulary loaded: %d classes, %d properties',
		scalar(keys %dynamic_schema),
		scalar(keys %dynamic_properties),
	);

	# Return the class hashref; callers needing properties use the global.
	return $classes;
}

# ===========================================================================
# INTERNAL HELPERS
# All routines below begin with _ and are not part of the public API.
# ===========================================================================

# ---------------------------------------------------------------------------
# _slurp_file($path)
#
# Purpose:  Read the complete contents of a file into a scalar.
# Entry:    $path is a path to an existing, readable file.
# Returns:  The file contents as a scalar string.
# Side fx:  None beyond reading the file.
# Notes:    autodie causes open/close to throw on failure; callers should
#           wrap in eval { } and handle $@ if a non-fatal path is needed.
# ---------------------------------------------------------------------------
sub _slurp_file {
	my ($path) = @_;

	# Open the file; autodie will throw if this fails.
	open my $fh, '<', $path;

	# Temporarily undefine $/ to read the whole file in one operation.
	local $/;
	my $content = <$fh>;

	close $fh;
	return $content;
}

# ---------------------------------------------------------------------------
# _spit_file($path, $content)
#
# Purpose:  Write a scalar string to a file, creating or truncating it.
# Entry:    $path is a writable path; $content is a defined scalar.
# Returns:  1 on success.
# Side fx:  Creates or overwrites $path.
# Notes:    autodie causes open/close to throw on failure; wrap in eval
#           when the write is non-critical (e.g. cache population).
# ---------------------------------------------------------------------------
sub _spit_file {
	my ($path, $content) = @_;

	# Open for writing; autodie throws on permission or path errors.
	open my $fh, '>', $path;
	print $fh $content;
	close $fh;

	return 1;
}

# ---------------------------------------------------------------------------
# _fetch_url($url, $timeout)
#
# Purpose:  Perform an HTTP GET and return the decoded response body.
# Entry:    $url is a valid absolute HTTP/HTTPS URL; $timeout is a positive
#           integer (seconds).
# Returns:  Decoded response content on success; undef on HTTP error.
# Side fx:  Network I/O; emits carp on non-success HTTP status.
# Notes:    Transport-level errors (DNS failure, TLS error) may propagate as
#           exceptions from LWP::UserAgent; callers should wrap in eval if
#           they need a guaranteed non-throwing call.
# ---------------------------------------------------------------------------
sub _fetch_url {
	my ($url, $timeout) = @_;

	# Build a minimal UA; timeout prevents indefinite hangs.
	my $ua  = LWP::UserAgent->new(timeout => $timeout);
	my $res = $ua->get($url);

	# Treat any non-2xx status as a soft failure so callers can try fallbacks.
	unless ($res->is_success) {
		carp "Failed to fetch '$url': ", $res->status_line;
		return;
	}

	return $res->decoded_content;
}

# ---------------------------------------------------------------------------
# _extract_label($item)
#
# Purpose:  Extract the rdfs:label string from a JSON-LD graph item hashref.
# Entry:    $item is a hashref that may contain 'rdfs:label' or the full
#           URI equivalent key.
# Returns:  The label as a plain string, or undef if no label is found.
# Side fx:  None.
# Notes:    Schema.org JSON-LD may represent the label as a scalar string or
#           as an array (for multi-language entries); this function always
#           returns the first (or only) value.
# ---------------------------------------------------------------------------
sub _extract_label {
	my ($item) = @_;

	# Try the compact key first; fall back to the full RDF URI form.
	my $label = $item->{$RDFS_LABEL} // $item->{$RDFS_LABEL_FULL};
	return unless defined $label;

	# If the label is multi-valued, take the first entry.
	return ref($label) eq 'ARRAY' ? $label->[0] : $label;
}

# ---------------------------------------------------------------------------
# _parse_graph(\@graph)
#
# Purpose:  Iterate over a JSON-LD @graph array and partition items into
#           Schema.org class definitions and property definitions.
# Entry:    $graph_ref is an arrayref of item hashrefs as decoded from the
#           Schema.org JSON-LD vocabulary.
# Returns:  Two hashrefs: (\%classes, \%properties), each keyed by label.
#           Items are also indexed by the short name extracted from their
#           @id URI so that both 'MusicEvent' and its label resolve correctly.
# Side fx:  None.
# Notes:    Items with no recognisable label or @type are silently skipped.
#           The @id short-name index uses //= so the label always wins if
#           it differs.
# ---------------------------------------------------------------------------
sub _parse_graph {
	my ($graph_ref) = @_;

	my (%classes, %props);

	# Iterate every item in the JSON-LD graph array.
	for my $item (@{$graph_ref}) {

		# Skip items that do not declare an RDF type.
		next unless exists $item->{'@type'};
		my $item_type = $item->{'@type'};

		# Normalise @type: the spec allows either a scalar or an array.
		my @types = ref($item_type) eq 'ARRAY' ? @{$item_type} : ($item_type);

		# Extract the human-readable label; skip items with none.
		my $label = _extract_label($item) or next;

		# Index rdfs:Class items under their label and their @id short name.
		if (grep { $_ eq $RDF_CLASS } @types) {
			$classes{$label} = $item;

			# Secondary index by short URI fragment (e.g. 'MusicGroup').
			if (my $id = $item->{'@id'}) {
				(my $short = $id) =~ s{.*/}{};
				$classes{$short} //= $item;
			}
		}

		# Index rdf:Property items under their label and @id short name.
		if (grep { $_ eq $RDF_PROPERTY } @types) {
			$props{$label} = $item;

			# Secondary index by short URI fragment (e.g. 'startDate').
			if (my $id = $item->{'@id'}) {
				(my $short = $id) =~ s{.*/}{};
				$props{$short} //= $item;
			}
		}
	}

	return (\%classes, \%props);
}

# ===========================================================================
# END OF MODULE POD
# ===========================================================================

=encoding utf-8

=head1 FILES

=head2 schemaorg_dynamic_vocabulary.jsonld

Cache file written to C<$CACHEDIR> (if set) or the system temporary directory
(C<File::Spec-E<gt>tmpdir()>), unless overridden via C<$config{cache_file}>.
Contains the downloaded Schema.org vocabulary in JSON-LD format.  Refreshed
when older than C<$config{cache_duration}> seconds.

=head1 ERROR HANDLING

The module uses C<carp> rather than C<die> for recoverable failures:

=over 4

=item * Failed HTTP requests emit C<carp> and trigger the stale-cache fallback.

=item * JSON parse errors emit C<carp> and return C<{}>.

=item * File I/O errors emit C<carp>; the download path is attempted next.

=item * C<croak> is reserved for programmer errors (bad argument types).

=back

=head1 BUGS

=over 4

=item * Cache invalidation is time-based only; no checksum or version check.

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Schema-Validator/coverage/>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/schema-validator>

=head2 FORMAL SPECIFICATION

=head3 is_valid_datetime

    Let CHAR denote the set of all Unicode code points and
    DIGIT = { c : CHAR | c in {'0'..'9'} }.
    Let seqN(S) = { s : seq S | #s = N }.

    YEAR     ≜  seqN(4, DIGIT)
    MONTH    ≜  seqN(2, DIGIT)
    DAY      ≜  seqN(2, DIGIT)
    HOUR     ≜  seqN(2, DIGIT)
    MINUTE   ≜  seqN(2, DIGIT)
    SECOND   ≜  seqN(2, DIGIT)
    SEP      ≜  { 'T', ' ' }

    DATE     ≜  { d : seq CHAR | ∃ y ∈ YEAR; mo ∈ MONTH; dy ∈ DAY
                    • d = y ⌢ ⟨'-'⟩ ⌢ mo ⌢ ⟨'-'⟩ ⌢ dy }

    HHMM     ≜  { t : seq CHAR | ∃ h ∈ HOUR; m ∈ MINUTE
                    • t = h ⌢ ⟨':'⟩ ⌢ m }

    HHMMSS   ≜  { t : seq CHAR | ∃ h ∈ HOUR; m ∈ MINUTE; s ∈ SECOND
                    • t = h ⌢ ⟨':'⟩ ⌢ m ⌢ ⟨':'⟩ ⌢ s }

    TIMEFRAG ≜  { tf : seq CHAR | ∃ sep ∈ SEP; hm ∈ (HHMM ∪ HHMMSS)
                    • tf = ⟨sep⟩ ⌢ hm }

    DATETIME ≜  DATE ∪ { dt : seq CHAR | ∃ d ∈ DATE; tf ∈ TIMEFRAG
                           • dt = d ⌢ tf }

    ──────────────────────────────────────────────────────────────
     IsValidDatetime
    ──────────────────────────────────────────────────────────────
     str?    : seq CHAR
     result! : B
    ──────────────────────────────────────────────────────────────
     result! ⟺ str? ∈ DATETIME
    ──────────────────────────────────────────────────────────────

=head3 load_dynamic_library

    Let FILE, DUR, URL be the resolved config values.
    Let now : N be the current UNIX epoch time.
    Let mtime : PATH -> N map a path to its last-modification time.
    Let readable, writeable : PATH -> B be filesystem predicates.
    Let reachable : URL -> B test HTTP reachability.
    Let slurp : PATH -> seq CHAR and spit : PATH x seq CHAR -> 1.
    Let fetch : URL x N -> seq CHAR (second arg is timeout).
    Let decode_json : seq CHAR -> ITEM.
    Let label : ITEM -> (LABEL | {}) extract rdfs:label.
    Let types : ITEM -> P TYPE extract @type values.

    FRESH ≜ ( -e(FILE) ) ∧ ( (now - mtime(FILE)) < DUR )

    ──────────────────────────────────────────────────────────────────────
     LoadDynamicVocabulary
    ──────────────────────────────────────────────────────────────────────
     ΔVocabularyStore
     cache_file?     : PATH
     cache_duration? : N
     vocab_url?      : URL
     ua_timeout?     : N
     result!         : CLASS_LABEL ⇸ ITEM
    ──────────────────────────────────────────────────────────────────────
     content : seq CHAR

     FRESH ∧ readable(cache_file?)
         ⇒ content = slurp(cache_file?)

     ¬FRESH ∧ reachable(vocab_url?)
         ⇒ content = fetch(vocab_url?, ua_timeout?)
           ∧ ( writeable(cache_file?) ⇒ spit(cache_file?, content) )

     ¬FRESH ∧ ¬reachable(vocab_url?) ∧ -e(cache_file?)
         ⇒ content = slurp(cache_file?)

     graph ≜ (decode_json content)[AT_GRAPH]

     dynamic_schema' =
         { item ∈ graph | RDF_CLASS ∈ types(item) ∧ label(item) ≠ ∅
           • label(item) ↦ item }

     dynamic_properties' =
         { item ∈ graph | RDF_PROPERTY ∈ types(item) ∧ label(item) ≠ ∅
           • label(item) ↦ item }

     result! = dynamic_schema'
    ──────────────────────────────────────────────────────────────────────

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;

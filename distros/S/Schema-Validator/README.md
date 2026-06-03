# NAME

Schema::Validator - Tools for validating and loading Schema.org vocabulary definitions

# VERSION

Version 0.03

# SYNOPSIS

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

# DESCRIPTION

`Schema::Validator` provides two utilities for working with Schema.org
structured data:

- ["is\_valid\_datetime"](#is_valid_datetime) -- validates a string against the ISO 8601
date/datetime subset used by Schema.org.
- ["load\_dynamic\_vocabulary"](#load_dynamic_vocabulary) -- downloads (and caches for 24 hours)
the full Schema.org JSON-LD vocabulary and exposes all class and property
definitions as a hashref and via package globals.

## Configuration

Runtime behaviour is controlled by the package-level `%Schema::Validator::config`
hash.  Supported keys and their defaults:

    cache_file     => "$CACHEDIR/schemaorg_dynamic_vocabulary.jsonld"  # or tmpdir
    cache_duration => 86400                                          # seconds
    vocab_url      => 'https://schema.org/.../schemaorg-current-https.jsonld'
    ua_timeout     => 30                                             # seconds

Override any key before calling an exported function:

    $Schema::Validator::config{ua_timeout} = 60;

Or supply a complete replacement via [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure):

    Object::Configure->configure('Schema::Validator', \%my_config);

# PACKAGE VARIABLES

## %dynamic\_schema

Package hash keyed by Schema.org class label (e.g. `Person`, `Event`).
Values are the raw item hashrefs from the JSON-LD `@graph` array.
Populated as a side-effect of ["load\_dynamic\_vocabulary"](#load_dynamic_vocabulary).

## %dynamic\_properties

Package hash keyed by Schema.org property label (e.g. `name`, `startDate`).
Values are the raw item hashrefs from the JSON-LD `@graph` array.
Populated as a side-effect of ["load\_dynamic\_vocabulary"](#load_dynamic_vocabulary).

# FUNCTIONS

## is\_valid\_datetime

### PURPOSE

Tests whether a scalar string conforms to one of the ISO 8601
date or datetime formats accepted by Schema.org:

    YYYY-MM-DD               (date only)
    YYYY-MM-DDTHH:MM         (T separator, no seconds)
    YYYY-MM-DD HH:MM         (space separator, no seconds)
    YYYY-MM-DDTHH:MM:SS      (T separator, with seconds)
    YYYY-MM-DD HH:MM:SS      (space separator, with seconds)

Optional timezone designators (`Z`, `+HH:MM`, `-HH:MM`) are **accepted**.
Calendar sanity **is** enforced: out-of-range values (e.g. month 99) are **rejected**.

### ARGUMENTS

- `string` (required, scalar) -- the candidate string to test.
Both positional (`is_valid_datetime('2024-11-14')`) and named
(`is_valid_datetime(string => '2024-11-14')`) calling conventions
are accepted.

### RETURNS

`1` if the string is in a supported format; `0` otherwise.
Returns `0` for `undef` or an empty string without throwing.

### SIDE EFFECTS

None.

### NOTES

Delegates to `DateTime::Format::ISO8601-`parse\_datetime()> for semantic
validation, so out-of-range values (e.g. month 99) are rejected.
The space-separator variant (`YYYY-MM-DD HH:MM`) is normalised to a T
separator before parsing since the module requires strict ISO 8601.
Timezone designators (`Z`, `+HH:MM`, `-HH:MM`) are now accepted.

### EXAMPLE

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

### API SPECIFICATION

#### Input (Params::Validate::Strict)

    {
        string => {
            type     => 'string',
            optional => 0,
        },
    }

#### Output (Return::Set)

    {
        type => 'boolean'
        description  => '1 (valid) or 0 (invalid, undef, or empty input)'
    }

## load\_dynamic\_vocabulary

### PURPOSE

Downloads the complete Schema.org vocabulary from the official JSON-LD
endpoint, parses it into class and property lookup tables, caches the raw
JSON-LD locally, and returns the class table as a hashref.

The cache is considered fresh for `cache_duration` seconds (default 24 hours).
On network failure the function falls back to a stale cache rather than
returning an empty result, and emits a `carp` warning.

### ARGUMENTS

All arguments are optional; defaults come from `%Schema::Validator::config`.

- `cache_file` (optional, scalar) -- path to the local cache file.
Defaults to `$config{cache_file}`: `$CACHEDIR/schemaorg_dynamic_vocabulary.jsonld`
if `$ENV{CACHEDIR}` is set, otherwise `File::Spec->tmpdir()` is used.
- `cache_duration` (optional, scalar) -- cache validity window in seconds.
Defaults to `$config{cache_duration}`.
- `vocab_url` (optional, scalar) -- URL of the JSON-LD vocabulary endpoint.
Defaults to `$config{vocab_url}`.
- `ua_timeout` (optional, scalar) -- LWP::UserAgent timeout in seconds.
Defaults to `$config{ua_timeout}`.

Both zero-argument and named calling conventions are supported:

    load_dynamic_vocabulary();
    load_dynamic_vocabulary(ua_timeout => 60);

### RETURNS

A hashref mapping class labels (e.g. `'Person'`) to their raw JSON-LD
definition hashrefs from the `@graph` array.

Returns an empty hashref `{}` on all failure paths (network unreachable,
no cache, JSON parse error).  Never throws.

### SIDE EFFECTS

- Populates `%Schema::Validator::dynamic_schema` with class definitions.
- Populates `%Schema::Validator::dynamic_properties` with property definitions.
- Creates or updates the local cache file on a successful download.
- Emits `carp` warnings on network failures, I/O errors, or JSON
parse errors.

### NOTES

The default cache directory is determined once at module load time: the
`$CACHEDIR` environment variable is used if set; otherwise `File::Spec->tmpdir()`
is used (typically `/tmp` on Unix).  Override for the session with:

    $Schema::Validator::config{cache_file} = '/my/path/vocab.jsonld';

The `bin/validate-schema` CLI tool imports this function from the module and
uses `cache_file => $path` to store its cache under `~/.cache/schema_validator/`.

### EXAMPLE

    use Schema::Validator qw(load_dynamic_vocabulary);

    my $classes = load_dynamic_vocabulary();
    printf "%d classes loaded\n", scalar keys %{$classes};

    # Check for a specific class in the returned hashref
    print "Has Person\n" if exists $classes->{'Person'};

    # Or query the package globals directly after the call
    Schema::Validator::load_dynamic_vocabulary();
    my @names = sort keys %Schema::Validator::dynamic_schema;

### API SPECIFICATION

#### Input (Params::Validate::Strict)

    {
        cache_file     => { type => 'string', optional => 1 },
        cache_duration => { type => 'string', optional => 1 },
        vocab_url      => { type => 'string', optional => 1 },
        ua_timeout     => { type => 'string', optional => 1 },
    }

#### Output (Return::Set)

    {
        type  => 'hashref',
        description  => 'class-label => JSON-LD item hashref'
        # ON_FAILURE   => 'empty hashref {}; never throws'
        # SIDE_EFFECTS => 'populates %dynamic_schema and %dynamic_properties'
    }

# FILES

## schemaorg\_dynamic\_vocabulary.jsonld

Cache file written to `$CACHEDIR` (if set) or the system temporary directory
(`File::Spec->tmpdir()`), unless overridden via `$config{cache_file}`.
Contains the downloaded Schema.org vocabulary in JSON-LD format.  Refreshed
when older than `$config{cache_duration}` seconds.

# ERROR HANDLING

The module uses `carp` rather than `die` for recoverable failures:

- Failed HTTP requests emit `carp` and trigger the stale-cache fallback.
- JSON parse errors emit `carp` and return `{}`.
- File I/O errors emit `carp`; the download path is attempted next.
- `croak` is reserved for programmer errors (bad argument types).

# BUGS

- Cache invalidation is time-based only; no checksum or version check.

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Schema-Validator/coverage/)

# REPOSITORY

[https://github.com/nigelhorne/schema-validator](https://github.com/nigelhorne/schema-validator)

## FORMAL SPECIFICATION

### is\_valid\_datetime

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

### load\_dynamic\_library

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

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

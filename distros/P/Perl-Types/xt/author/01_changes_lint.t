# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.015_000;

# [[[ INCLUDES ]]]
use Test2::V0;
use English qw(-no_match_vars);
use version;  # for version::is_strict()

BEGIN {
    # optional banner when running with PERL_VERBOSE=1 in CI or locally
    if ( $ENV{PERL_VERBOSE} ) {
        diag('[[[ Beginning Change Log Lint Tests ]]]');
    }
}

# this is an authors-only test, skip if not explicitly enabled by AUTHOR_TESTING or RELEASE_TESTING
if (not ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING})) {
    plan skip_all => 'author test; `export AUTHOR_TESTING=1` to run';  # skip all tests if env vars are not set
}

# [[[ HELPER SUBROUTINES ]]]

# strict ISO-8601 validator with numeric range checks;
# accepts: YYYY-MM-DD
#          YYYY-MM-DDThh:mm
#          YYYY-MM-DDThh:mm:ss
#          YYYY-MM-DDThh:mm:ss.sss
# with optional Z or ±hh:mm (or ±hh:mm:ss) offset;
# returns true if valid; false otherwise
sub is_valid_iso8601 {
    my ($possible_date) = @ARG;
#    if ($ENV{PERL_DEBUG}) { diag('in is_valid_iso8601(), received $possible_date = ', $possible_date, "\n"); }

    if ( not defined $possible_date ) { return 0; }
    my $regular_expression = qr{
        \A
        (\d{4})-(\d{2})-(\d{2})                    # 1:year 2:month 3:day
        (?:                                        # optional time part
          [T ]                                     # T or space
          (\d{2}):(\d{2})                          # 4:hour 5:minute
          (?:
            :(\d{2})                               # 6:second
            (?:\.(\d{1,9}))?                       # 7:fraction
          )?
          (?:                                      # optional zone
            Z
            |
            ([+-])(\d{2}):(\d{2})(?::(\d{2}))?     # 8:sign 9:zh 10:zm 11:zs
          )?
        )?
        \z
    }x;

    if ( $possible_date !~ $regular_expression ) { return 0; }

    my ($year, $month, $day, $hours, $minutes, $seconds, $fractional_seconds, $time_zone_sign, $time_zone_hours, $time_zone_minutes, $time_zone_seconds) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);

    # month range
    if ( ($month < 1) or ($month > 12) ) { return 0; }

    # days per month with leap-year handling for February
    my @days_in_month = (undef,31,28,31,30,31,30,31,31,30,31,30,31);
    my $is_leap = 0;
    if ( ($year % 4 == 0) and (($year % 100 != 0) or ($year % 400 == 0)) ) {
        $is_leap = 1;
    }
    if ( ($month == 2) and ($is_leap) ) {
        $days_in_month[2] = 29;
    }
    if ( ($day < 1) or ($day > $days_in_month[$month]) ) { return 0; }

    # time part, if present
    if ( defined $hours ) {
        if ( ($hours < 0) or ($hours > 23) ) { return 0; }
        if ( ($minutes < 0) or ($minutes > 59) ) { return 0; }
        if ( defined $seconds ) {
            # allow leap second 60
            if ( ($seconds < 0) or ($seconds > 60) ) { return 0; }
        }
        if ( defined $time_zone_sign ) {
            if ( ($time_zone_hours < 0) or ($time_zone_hours > 23) ) { return 0; }
            if ( ($time_zone_minutes < 0) or ($time_zone_minutes > 59) ) { return 0; }
            if ( defined $time_zone_seconds ) {
                if ( ($time_zone_seconds < 0) or ($time_zone_seconds > 59) ) { return 0; }
            }
        }
    }

    return 1;
}


# decide whether a version string is acceptable;
# "{{$NEXT}}" token is always allowed without parsing, otherwise use "version::is_strict()"
sub is_valid_version_string {
    my ($possible_version) = @ARG;
#    if ($ENV{PERL_DEBUG}) { diag('in is_valid_version_string(), received $possible_version = ', $possible_version, "\n"); }

    if ( not defined $possible_version ) { return 0; }
    elsif ( $possible_version eq '{{$NEXT}}' ) { return 1; }
    elsif ( version::is_strict($possible_version) ) { return 1; }
    else { return 0; }
}


# detect a bare date line, which is a line that is only an ISO-8601 date/time,
# with optional trailing Olson zone like "America/Chicago", but no other text;
# this helps catch a date appearing without any preceding version header
sub is_bare_date_line {
    my ($line) = @ARG;
#    if ($ENV{PERL_DEBUG}) { diag('in is_bare_date_line(), received $line = ', $line, "\n"); }

    if ( not defined $line ) { return 0; }
    if ( $line =~ /\A\s*([0-9]{4}-[0-9]{2}-[0-9]{2}(?:[T ][0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\.\d{1,9})?)?(?:Z|[+-][0-9]{2}:[0-9]{2}(?::[0-9]{2})?)?)?)\s*([A-Za-z][A-Za-z0-9_\-\/]*(?:\s+[A-Za-z][A-Za-z0-9_\-\/]*)*)?\s*\z/ ) {
        my $date = $1;
        if ( is_valid_iso8601($date) ) {
            return 1;
        }
    }
    return 0;
}


# detect a release header for the raw file scan, very similar to what CPAN::Changes::Parser accepts
sub is_release_header_line {
    my ($line) = @ARG;
#    if ($ENV{PERL_DEBUG}) { diag('in is_release_header_line(), received $line = ', $line, "\n"); }

    if ( not defined $line ) { return 0; }
    my $version = qr/\{\{\$NEXT\}\}|v?\d+(?:\.\d+)*(?:_[0-9]+)?(?:-TRIAL)?/;
    if ( $line =~ /\A\s*(?:version|revision)?\s*(?:$version)(?:[[:punct:]\s].*)?\z/i ) {
        return 1;
    }
    return 0;
}


# extract version token & ISO date string from a header-like line,
# returns both or an empty list if not matched;
# we purposefully allow any non-space token as the version candidate here,
# so we can catch invalid versions like "0.2x00 2025-..." which CPAN::Changes would ignore
sub capture_header_like {
    my ($line) = @ARG;
#    if ($ENV{PERL_DEBUG}) { diag('in capture_header_like(), received $line = ', $line, "\n"); }

    if ( not defined $line ) { return (); }
    my $date_re = qr/[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[T ][0-9]{2}:[0-9]{2}(?::[0-9]{2}(?:\.\d{1,9})?)?(?:Z|[+-][0-9]{2}:[0-9]{2}(?::[0-9]{2})?)?)?/;
    if ( $line =~ /\A\s*(?:version|revision)?\s*([^\s]+)\s+($date_re)(?:\s+[A-Za-z][A-Za-z0-9_\-\/]*(?:\s+[A-Za-z][A-Za-z0-9_\-\/]*)*)?\s*\z/i ) {
        my $v = $1;
        my $d = $2;
        return ($v, $d);
    }
    return ();
}


# [[[ DEPENDENCY LOADING ]]]

# load CPAN::Changes using a block eval;
# if missing, skip this author test gracefully for end users
my $have_cpan_changes = 0;
eval {
    require CPAN::Changes;  # may die if not installed
    $have_cpan_changes = 1;
    1;  # explicit true to avoid undef from eval()
};

if ( not $have_cpan_changes ) {
    my $reason = 'CPAN::Changes required for this author test';
    if ( (defined $EVAL_ERROR) and (length $EVAL_ERROR) ) {
        $reason = $reason . '; load error: ' . $EVAL_ERROR;
    }
    plan skip_all => $reason;
}

# [[[ PRE-LINT TESTS ]]]

my $changes_file_name = 'Changes';

# TEST 1: file must exist
if ( -f $changes_file_name ) {
    ok( 1, q{'Changes' file exists} );
}
else {
    ok( 0, q{'Changes' file exists} );
    done_testing();
    exit 0;
}

# TEST 2: parse the file; treat "{{$NEXT}}" as a version-like token;
# use block eval to convert parser exceptions into test diagnostics
my $changes_object;
my $parsed = 0;
eval {
    # IMPORTANT: pass next_token so {{$NEXT}} is recognized as a release
    $changes_object = CPAN::Changes->load( $changes_file_name, next_token => qr/\{\{\$NEXT\}\}/ );
    $parsed  = 1;
    1;
};
if ($parsed) {
    ok( 1, 'Changes parses cleanly via CPAN::Changes->load(next_token => {{$NEXT}})' );
}
else {
    ok( 0, 'Changes parses cleanly via CPAN::Changes->load(next_token => {{$NEXT}})' );
    diag($EVAL_ERROR);
    done_testing();
    exit 0;
}

# TEST 3: sanity check, ensure we have the right object type
if (defined $changes_object) {
    ok( $changes_object->isa('CPAN::Changes'), 'Loaded object is CPAN::Changes' );
}
else {
    ok( 0, 'Loaded object is CPAN::Changes' );
    done_testing();
    exit 0;
}

# [[[ LINT TESTS ]]]

# gather releases and versions
my @releases = ();
if (defined $changes_object) {
    @releases = $changes_object->releases();
}
my @versions = map { $ARG->version } @releases;

# configuration flag
my $require_release_with_version_number = 0;

# NEED ANSWER: during `dzil build`, is RELEASE_TESTING somehow automatically set to 1?  and if so, will Dist::Zilla::Plugin::NextRelease properly replace "{{$NEXT}}" with a real version number before these '01_changes_lint.t' tests are run??
if ( (exists $ENV{RELEASE_TESTING}) and ($ENV{RELEASE_TESTING}) ) {
    $require_release_with_version_number = 1;
}

# TEST 4: at most one {{$NEXT}} section
my $next_count = 0;
foreach my $v (@versions) {
    if ( (defined $v) and ($v eq '{{$NEXT}}') ) {
        $next_count = $next_count + 1;
    }
}
if ( $next_count <= 1 ) {
    ok( 1, 'At most one {{$NEXT}} section present' );
}
else {
    ok( 0, 'At most one {{$NEXT}} section present' );
    diag('Found ' . $next_count . ' {{$NEXT}} sections; expected 0 or 1.');
}

# TEST 5: no duplicate numeric version headers, does not include "{{$NEXT}}"
my %seen_numeric = ();
my @duplicate_versions = ();
foreach my $version (@versions) {
    if ( (defined $version) and ($version ne '{{$NEXT}}') ) {
        if ( exists $seen_numeric{$version} ) {
            push @duplicate_versions, $version;
        }
        else {
            $seen_numeric{$version} = 1;
        }
    }
}
if ( scalar(@duplicate_versions) == 0 ) {
    ok( 1, 'No duplicate release versions' );
}
else {
    ok( 0, 'No duplicate release versions' );
    diag('Duplicate versions: ' . join(', ', @duplicate_versions));
}

# TEST 6: preamble should contain exactly one "Revision history for …" header
my $preamble = '';
if (defined $changes_object) {
    my $possible_preamble = $changes_object->preamble();
    if (defined $possible_preamble) {
        $preamble = $possible_preamble;
    }
}
my @headers = ();
if ( (defined $preamble) and (length $preamble) ) {
    @headers = ( $preamble =~ /^(?:Revision history for .+)\s*$/mg );
}
if ( scalar(@headers) == 1 ) {
    ok( 1, 'Preamble contains exactly one "Revision history for ..." header' );
}
else {
    ok( 0, 'Preamble contains exactly one "Revision history for ..." header' );
    diag('Found ' . scalar(@headers) . ' top headers in preamble; expected exactly 1.');
}

# TEST 7: numbered release requirement, configurable via $require_release_with_version_number
my @numeric_releases = grep { (defined $ARG->version) and ($ARG->version ne '{{$NEXT}}') } @releases;
if ( $require_release_with_version_number ) {
    if ( scalar(@numeric_releases) >= 1 ) {
        ok( 1, 'At least one numbered release is present' );
    }
    else {
        ok( 0, 'At least one numbered release is present' );
        diag('Only {{$NEXT}} present; add a numbered release when shipping.');
    }
}
else {
    ok( 1, 'Numbered release not required, accept Changes with only {{$NEXT}} present' );
}

# TEST 8: valid version strings for numbered releases
my @bad_versions = ();
foreach my $numeric_release (@numeric_releases) {
    my $possible_version = $numeric_release->version();
    if ( not is_valid_version_string($possible_version) ) {
        my $bad_version_line_number = 'line ' . $numeric_release->line();
        push @bad_versions, $possible_version . ' (' . $bad_version_line_number . ')';
    }
}
if ( scalar(@bad_versions) == 0 ) {
    ok( 1, 'All numbered release versions are valid' );
}
else {
    ok( 0, 'All numbered release versions are valid' );
    diag('Invalid version strings: ' . join(', ', @bad_versions));
}

# TESTS 9 & 10: date presence & strict ISO-8601 validation for numbered releases;
# we validate the normalized date that CPAN::Changes provides via "$numeric_release->date()",
# which avoids relying on Test::CPAN::Changes' "raw_date" subclass
my @missing_dates = ();
my @bad_dates = ();
foreach my $numeric_release (@numeric_releases) {
    my $date = $numeric_release->date();  # normalized date string
    if ( (not defined $date) or (length $date) == 0 ) {
        push @missing_dates, ($numeric_release->version() . ' (line ' . $numeric_release->line() . ')');
    }
    else {
        # allow explicit “Unknown …” tokens exactly (parser emits these sometimes)
        my $is_unknown_date = 0;
        if ( $date =~ /\A(?:Unknown(?:\s+Release\s+Date)?|Not\s+Released|Development(?:\s+Release)?|Developer\s+Release)\z/i ) {
            $is_unknown_date = 1;
        }
        if ( not $is_unknown_date ) {
            if ( not is_valid_iso8601($date) ) {
                push @bad_dates, ($numeric_release->version() . ' normalized date "' . $date . '" (line ' . $numeric_release->line . ')');
            }
        }
    }
}

if ( scalar(@missing_dates) == 0 ) {
    ok( 1, 'All numbered releases have a date' );
}
else {
    ok( 0, 'All numbered releases have a date' );
    diag('Missing date for: ' . join(', ', @missing_dates));
}

if ( scalar(@bad_dates) == 0 ) {
    ok( 1, 'All numbered release dates are strict ISO-8601 (or explicit Unknown)' );
}
else {
    ok( 0, 'All numbered release dates are strict ISO-8601 (or explicit Unknown)' );
    diag('Non-ISO dates: ' . join('; ', @bad_dates));
}

# TEST 11: bare date line before any version header is not allowed;
# this catches a date line floating at top-of-file or before the first header
my @rogue_dates = ();
my $seen_release_header = 0;
my $line_count = 0;
my $filehandle;
if ( open $filehandle, '<', $changes_file_name ) {
    while ( my $line = <$filehandle> ) {
        $line_count = $line_count + 1;
        if ( is_release_header_line($line) ) {
            $seen_release_header = 1;
        }
        else {
            if ( is_bare_date_line($line) ) {
                if ( not $seen_release_header ) {
                    push @rogue_dates, ('line ' . $line_count . ': ' . $line);
                }
            }
        }
    }
    close $filehandle;
}
else {
    diag('Could not open ' . $changes_file_name . ': ' . $OS_ERROR);
}

if ( scalar(@rogue_dates) == 0 ) {
    ok( 1, 'No bare date line appears before the first release header' );
}
else {
    ok( 0, 'No bare date line appears before the first release header' );
    diag('Found rogue date lines: ' . join('', @rogue_dates));
}

# TEST 12: extra raw lint, flag "header-like" lines with a date where the version token is invalid;
# this catches cases like:  "0.2x00     2025-06-05 02:54:51-05:00 America/Chicago"
# which CPAN::Changes will ignore and thus our loop over "$changes_object->releases()" will never see
my @invalid_header_like = ();
$line_count = 0;
if ( open $filehandle, '<', $changes_file_name ) {
    while ( my $line = <$filehandle> ) {
        $line_count = $line_count + 1;

        # only care about lines that look like "<token> <date...>"
        my ($possible_version, $possible_date) = capture_header_like($line);
        if ( defined $possible_version ) {

            # allow "{{$NEXT}}" headers even if they carry a date; this is unusual, but do not hard-fail here;
            # NEED ANSWER: is this the correct behavior, or does it clash with Dist::Zilla::Plugin::NextRelease?
            if ( $possible_version ne '{{$NEXT}}' ) {
                # if the date part is actually a valid ISO-8601, then this is a bona fide header-like line
                if ( is_valid_iso8601($possible_date) ) {
                    # if the version token would NOT be accepted by version::is_strict(), then flag it
                    if ( not is_valid_version_string($possible_version) ) {
                        my $invalid_header_message = 'line ' . $line_count . ': invalid release header version token "' . $possible_version . '" with date ' . $possible_date;
                        push @invalid_header_like, $invalid_header_message;
                    }
                }
            }
        }
    }
    close $filehandle;
}
else {
    diag('Could not open ' . $changes_file_name . ' for extra raw lint: ' . $OS_ERROR);
}

if ( scalar(@invalid_header_like) == 0 ) {
    ok( 1, 'No header-like lines with a valid date have an invalid version token' );
}
else {
    ok( 0, 'No header-like lines with a valid date have an invalid version token' );
    diag(join("\n", @invalid_header_like));
}

# optional notes when verbose
if ( $ENV{PERL_VERBOSE} ) {
    diag('Parsed ' . scalar(@releases) . ' release section(s);');
    diag('Found ' . $next_count . ' {{$NEXT}} section(s);');
    if ( $require_release_with_version_number ) {
        diag('$require_release_with_version_number is true, so env var RELEASE_TESTING must be true');
    }
    else {
        diag('$require_release_with_version_number is false, so env var RELEASE_TESTING must be false');
    }
}

done_testing();

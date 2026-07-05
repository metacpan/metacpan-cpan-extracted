# NAME

Test::CPAN::Health - Analyse a CPAN distribution and produce a comprehensive health report

# VERSION

Version 0.1.0

# SYNOPSIS

**Command-line (the usual entry point):**

    # Analyse the current directory
    cpan-health .

    # Analyse by CPAN dist name (downloads and unpacks automatically)
    cpan-health LWP-UserAgent

    # Analyse by module name
    cpan-health LWP::UserAgent

    # JSON output -- useful for editor or CI integration
    cpan-health --format=json My-Dist

    # Fail the build if the health score falls below 80
    cpan-health --min-score=80 --no-cover My-Dist

    # Skip slow or network-dependent checks
    cpan-health --no-network --no-cover .

    # Run only the security and versioning checks
    cpan-health --check=security_advisories,sem_ver My-Dist

    # Skip specific checks by id
    cpan-health --skip=cpan_testers,kwalitee .

    # TAP output -- pipe into any test harness
    cpan-health --format=tap My-Dist | prove --stdin

    # Write the report to a file
    cpan-health --format=json --output=report.json LWP-UserAgent

    # Show all available options
    cpan-health --help

**Perl API (for programmatic use):**

    use Test::CPAN::Health;

    # Analyse a local unpacked distribution
    my $health = Test::CPAN::Health->new(path => '/path/to/My-Dist-1.00');
    my $report = $health->analyse;
    $health->report_to($report);

    # Analyse a distribution by CPAN dist name
    my $health = Test::CPAN::Health->new(
        dist      => 'LWP-UserAgent',
        format    => 'json',
        min_score => 80,
    );
    my $report = $health->analyse;
    exit 1 if $report->overall_score < 80;

    # Analyse by module name, skipping network-dependent checks
    my $health = Test::CPAN::Health->new(
        module     => 'LWP::UserAgent',
        no_network => 1,
        skip       => ['Test::CPAN::Health::Check::CPANTesters'],
    );

# DESCRIPTION

Test::CPAN::Health is a comprehensive distribution health checker for CPAN
modules -- analogous to `cargo audit` + `npm audit` + `go vet` +
`perlcritic` + `cpants`, all unified into a single scored report.

It accepts a distribution as a local path, a CPAN distribution name, or a
module name.  It runs a configurable battery of checks (POD coverage, CPAN
Testers pass rate, kwalitee, CI configuration, META validity, SPDX license,
stale and abandoned dependencies, known CVEs, reverse dependency count,
documentation quality, examples, benchmarks, semantic versioning, perlcritic
violations, code complexity, duplicate code, test coverage, minimum Perl
version, and deprecation warnings) and returns a weighted score out of 100.

The report can be rendered as coloured terminal output, JSON, HTML, or TAP
(allowing cpan-health to run inside a standard test harness).

# LIMITATIONS

- The `TestCoverage` check requires `Devel::Cover` and must run the
distribution's own test suite, which is slow and may have side effects.
- Network-dependent checks (CPANTesters, StaleDeps, AbandonedDeps,
SecurityAdvisories, ReverseDeps) require internet access and are subject to
upstream API availability and rate limits.
- The `DuplicateCode` check uses a token-fingerprint algorithm via
`PPI` and may produce false positives on generated or data-heavy code.

## analyse

Runs all configured checks against the distribution and returns a Report.

All components (Distribution, Cache, Runner, Reporter) are initialised
lazily on the first call so that construction is always cheap.

### API SPECIFICATION

#### INPUT

No arguments.  Configuration comes from the constructor.

#### OUTPUT

Returns a [Test::CPAN::Health::Report](https://metacpan.org/pod/Test%3A%3ACPAN%3A%3AHealth%3A%3AReport) object.

### MESSAGES

    Code  | Severity | Message                            | Resolution
    ------+----------+------------------------------------+---------------------
          |          |                                    |

### FORMAL SPECIFICATION

    -- Z schema (placeholder) --
    AnalyseOp
    Test::CPAN::Health
    Report'
    -------------------------------------------------------
    distribution /= undefined
    Report' = Runner.run(distribution)
    overall_score(Report') in 0..100

### SIDE EFFECTS

May download the distribution from CPAN, run its test suite (if
`TestCoverage` is enabled), and write to the local HTTP cache.

### USAGE EXAMPLE

    my $report = $health->analyse;
    print 'Score: ', $report->overall_score, "\n";

## list\_checks

### PURPOSE

Return a list of all default check metadata (id, name, weight, category,
description) without running any check.  Suitable for `--list-checks` output.

### API SPECIFICATION

#### INPUT

None (class method).

#### OUTPUT

Arrayref of hashrefs; each has keys `id`, `name`, `weight`, `category`,
`description`.  Ordered as they would execute.

### MESSAGES

    Code  | Severity | Message                             | Resolution
    ------+----------+-------------------------------------+---------------------
          |          |                                     |

### FORMAL SPECIFICATION

    Post: result is an arrayref of length = #DEFAULT_CHECKS (skipping unloadable)

### SIDE EFFECTS

Requires each check class (lazy load).

### USAGE EXAMPLE

    my @checks = @{ Test::CPAN::Health->list_checks };
    printf "%-20s %s\n", $_->{id}, $_->{name} for @checks;

## report\_to

Render a Report to the configured output format and return the result
as a string.  Printing to STDOUT (for terminal/TAP formats) is the
responsibility of the caller or the CLI script.

### API SPECIFICATION

#### INPUT

    report  Test::CPAN::Health::Report  required

#### OUTPUT

Scalar string containing the rendered report.

### MESSAGES

    Code  | Severity | Message                            | Resolution
    ------+----------+------------------------------------+---------------------
          |          |                                    |

### FORMAL SPECIFICATION

    -- Z schema (placeholder) --
    RenderOp
    reporter : Reporter
    report   : Report
    output   : String
    -------------------------------------------------------
    output = reporter.render(report)

### SIDE EFFECTS

None beyond invoking the reporter.

### USAGE EXAMPLE

    my $text = $health->report_to($report);
    print $text;

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

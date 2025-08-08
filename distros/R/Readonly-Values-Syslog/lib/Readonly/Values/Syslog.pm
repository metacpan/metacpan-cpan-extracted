package Readonly::Values::Syslog;

use strict;
use warnings;
use v5.14;	# Enable modern Perl features

# Core dependencies
use Carp qw(croak carp);
use Readonly;
use Readonly::Enum;
use Exporter qw(import);
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.04';

=head1 NAME

Readonly::Values::Syslog - RFC 3164 compliant syslog severity level constants

=head1 VERSION

Version 0.04

=head1 DESCRIPTION

This module provides RFC 3164 compliant syslog severity level constants and
utility functions for syslog level validation and conversion. It offers both
numeric constants and string-based lookups with comprehensive validation.

=head1 SYNOPSIS

    use Carp qw(croak);
    use Readonly::Values::Syslog qw(:all);

    # Using numeric constants
    my $level = $CRITICAL;  # 2

    # Using string-to-numeric conversion
    my $numeric_level = get_syslog_level('critical');  # 2
    $numeric_level = get_syslog_level('crit');      # 2 (alias)

    # Using numeric-to-string conversion
    my $level_name = get_syslog_name(2);               # 'critical'

    # Validation
    if (is_valid_syslog_level('warning')) {
        print "Valid syslog level\n";
    }

    if (is_valid_syslog_number(4)) {
        print "Valid syslog number\n";
    }

    # Get all available levels
    my @levels = get_all_syslog_levels();          # String names
    my @numbers = get_all_syslog_numbers();        # Numeric values

    # Comprehensive example
    sub log_message {
        my ($level, $message) = @_;

        my $numeric_level = eval { get_syslog_level($level) };
        if ($@) {
            croak "Invalid syslog level: $level";
        }

        my $level_name = get_syslog_name($numeric_level);
        printf "[%s:%d] %s\n", uc($level_name), $numeric_level, $message;
    }

=head1 RFC 3164 COMPLIANCE

This module implements the syslog severity levels as defined in RFC 3164:

    0  Emergency   - System is unusable
    1  Alert       - Action must be taken immediately
    2  Critical    - Critical conditions
    3  Error       - Error conditions
    4  Warning     - Warning conditions
    5  Notice      - Normal but significant condition
    6  Info        - Informational messages
    7  Debug       - Debug-level messages

=cut

Readonly::Enum our ($SYSLOG_EMERGENCY, $SYSLOG_ALERT, $SYSLOG_CRITICAL, $SYSLOG_ERROR, $SYSLOG_WARNING, $SYSLOG_NOTICE, $SYSLOG_INFO, $SYSLOG_DEBUG) => 0;

# Export the constants with traditional names for backward compatibility
Readonly our $EMERGENCY     => $SYSLOG_EMERGENCY;
Readonly our $ALERT         => $SYSLOG_ALERT;
Readonly our $CRITICAL      => $SYSLOG_CRITICAL;
Readonly our $ERROR         => $SYSLOG_ERROR;
Readonly our $WARNING       => $SYSLOG_WARNING;
Readonly our $NOTICE        => $SYSLOG_NOTICE;
Readonly our $INFORMATIONAL => $SYSLOG_INFO;
Readonly our $DEBUG         => $SYSLOG_DEBUG;

# Comprehensive string to numeric mapping with common aliases
Readonly::Hash our %SYSLOG_LEVELS => (
	# Primary names (RFC 3164)
	'emergency'     => $SYSLOG_EMERGENCY,
	'alert'         => $SYSLOG_ALERT,
	'critical'      => $SYSLOG_CRITICAL,
	'error'         => $SYSLOG_ERROR,
	'warning'       => $SYSLOG_WARNING,
	'notice'        => $SYSLOG_NOTICE,
	'informational' => $SYSLOG_INFO,
	'info'          => $SYSLOG_INFO,
	'debug'         => $SYSLOG_DEBUG,

	# Common aliases
	'emerg'         => $SYSLOG_EMERGENCY,
	'crit'          => $SYSLOG_CRITICAL,
	'err'           => $SYSLOG_ERROR,
	'warn'          => $SYSLOG_WARNING,
	'trace'         => $SYSLOG_DEBUG,      # Common in many logging systems

	# Alternative forms
	'panic'         => $SYSLOG_EMERGENCY,  # Historical alias
	'fatal'         => $SYSLOG_CRITICAL,   # Common in application logging
);

# Reverse mapping for numeric to string conversion
Readonly::Hash our %SYSLOG_NAMES => (
	$SYSLOG_EMERGENCY => 'emergency',
	$SYSLOG_ALERT     => 'alert',
	$SYSLOG_CRITICAL  => 'critical',
	$SYSLOG_ERROR     => 'error',
	$SYSLOG_WARNING   => 'warning',
	$SYSLOG_NOTICE    => 'notice',
	$SYSLOG_INFO      => 'info',
	$SYSLOG_DEBUG     => 'debug',
);

# Enhanced descriptions for documentation and tooling
Readonly::Hash our %SYSLOG_DESCRIPTIONS => (
	$SYSLOG_EMERGENCY => 'System is unusable',
	$SYSLOG_ALERT     => 'Action must be taken immediately',
	$SYSLOG_CRITICAL  => 'Critical conditions',
	$SYSLOG_ERROR     => 'Error conditions',
	$SYSLOG_WARNING   => 'Warning conditions',
	$SYSLOG_NOTICE    => 'Normal but significant condition',
	$SYSLOG_INFO      => 'Informational messages',
	$SYSLOG_DEBUG     => 'Debug-level messages',
);

# Backward compatibility - maintain old hash name but mark as deprecated
our %syslog_values = %SYSLOG_LEVELS;

=head1 FUNCTIONS

=head2 get_syslog_level($level_name)

Converts a syslog level name (string) to its numeric value.

    my $numeric = get_syslog_level('critical');  # Returns 2
    my $numeric = get_syslog_level('crit');      # Returns 2 (alias)

Dies with a descriptive error if the level name is invalid.

=cut

sub get_syslog_level {
    my $level_name = $_[0];

    unless (defined $level_name) {
        croak 'get_syslog_level: level name is required';
    }

    # Normalize to lowercase for lookup
    $level_name = lc($level_name);
    $level_name =~ s/^\s+|\s+$//g;  # Trim whitespace

    unless (exists $SYSLOG_LEVELS{$level_name}) {
        croak "get_syslog_level: invalid syslog level '$level_name'. " .
              "Valid levels are: " . join(', ', sort keys %SYSLOG_LEVELS);
    }

    return $SYSLOG_LEVELS{$level_name};
}

=head2 get_syslog_name($level_number)

Converts a numeric syslog level to its canonical string name.

    my $name = get_syslog_name(2);  # Returns 'critical'

Dies with a descriptive error if the level number is invalid.

=cut

sub get_syslog_name {
    my $level_number = $_[0];

    unless (defined $level_number) {
        croak 'get_syslog_name: level number is required';
    }

    unless (looks_like_number($level_number)) {
        croak "get_syslog_name: level must be numeric, got '$level_number'";
    }

    # Convert to integer for exact matching
    $level_number = int($level_number);

    unless (exists $SYSLOG_NAMES{$level_number}) {
        croak "get_syslog_name: invalid syslog level number '$level_number'. " .
              "Valid levels are: " . join(', ', sort { $a <=> $b } keys %SYSLOG_NAMES);
    }

    return $SYSLOG_NAMES{$level_number};
}

=head2 is_valid_syslog_level($level_name)

Returns true if the given string is a valid syslog level name (including aliases).

    if (is_valid_syslog_level('warning')) {
        # Process the warning
    }

=cut

sub is_valid_syslog_level {
    my $level_name = $_[0];

    return 0 unless defined $level_name;

    $level_name = lc($level_name);
    $level_name =~ s/^\s+|\s+$//g;

    return exists $SYSLOG_LEVELS{$level_name};
}

=head2 is_valid_syslog_number($level_number)

Returns true if the given number is a valid syslog severity level.

    if (is_valid_syslog_number(4)) {
        # Process the warning level (4)
    }

=cut

sub is_valid_syslog_number {
    my $level_number = $_[0];

    return 0 unless defined $level_number;
    return 0 unless looks_like_number($level_number);

    return exists $SYSLOG_NAMES{$level_number};
}

=head2 get_syslog_description($level)

Returns the RFC 3164 description for a syslog level. Accepts either numeric
level or string name.

    my $desc = get_syslog_description(2);           # 'Critical conditions'
    my $desc = get_syslog_description('critical');  # 'Critical conditions'

=cut

sub get_syslog_description {
    my $level = $_[0];

    unless (defined $level) {
        croak 'get_syslog_description: level is required';
    }

    my $numeric_level;

    if (looks_like_number($level)) {
        $numeric_level = int($level);
        unless (exists $SYSLOG_NAMES{$numeric_level}) {
            croak "get_syslog_description: invalid numeric level '$level'";
        }
    } else {
        $numeric_level = eval { get_syslog_level($level) };
        if ($@) {
            croak "get_syslog_description: invalid level name '$level'";
        }
    }

    return $SYSLOG_DESCRIPTIONS{$numeric_level};
}

=head2 get_all_syslog_levels()

Returns a list of all valid syslog level names (strings) in severity order.

    my @levels = get_all_syslog_levels();
    # Returns: ('emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug')

=cut

sub get_all_syslog_levels {
    return map { $SYSLOG_NAMES{$_} } sort { $a <=> $b } keys %SYSLOG_NAMES;
}

=head2 get_all_syslog_numbers()

Returns a list of all valid syslog level numbers in order.

    my @numbers = get_all_syslog_numbers();
    # Returns: (0, 1, 2, 3, 4, 5, 6, 7)

=cut

sub get_all_syslog_numbers {
    return sort { $a <=> $b } keys %SYSLOG_NAMES;
}

=head2 get_all_syslog_aliases()

Returns a hash reference mapping all aliases to their canonical names.

    my $aliases = get_all_syslog_aliases();
    # $aliases = { 'crit' => 'critical', 'err' => 'error', ... }

=cut

sub get_all_syslog_aliases {
    my %aliases;

    for my $alias (keys %SYSLOG_LEVELS) {
        my $numeric = $SYSLOG_LEVELS{$alias};
        my $canonical = $SYSLOG_NAMES{$numeric};

        # Only include if it's not the canonical name
        if ($alias ne $canonical) {
            $aliases{$alias} = $canonical;
        }
    }

    return \%aliases;
}

=head2 compare_syslog_levels($level1, $level2)

Compares two syslog levels and returns -1, 0, or 1 similar to cmp.
Accepts both numeric and string levels.

    my $cmp = compare_syslog_levels('error', 'warning');  # Returns -1 (error < warning)
    my $cmp = compare_syslog_levels(2, 4);               # Returns -1 (critical < warning)

=cut

sub compare_syslog_levels {
    my ($level1, $level2) = @_;

    unless (defined $level1 && defined $level2) {
        croak 'compare_syslog_levels: both levels are required';
    }

    # Convert both to numeric for comparison
    my $num1 = looks_like_number($level1) ? int($level1) : get_syslog_level($level1);
    my $num2 = looks_like_number($level2) ? int($level2) : get_syslog_level($level2);

    return $num1 <=> $num2;
}

# Export control
our @EXPORT = qw(
    $EMERGENCY $ALERT $CRITICAL $ERROR $WARNING $NOTICE $INFORMATIONAL $DEBUG
    %syslog_values %SYSLOG_LEVELS
);

our @EXPORT_OK = qw(
    get_syslog_level get_syslog_name is_valid_syslog_level is_valid_syslog_number
    get_syslog_description get_all_syslog_levels get_all_syslog_numbers
    get_all_syslog_aliases compare_syslog_levels
    %SYSLOG_NAMES %SYSLOG_DESCRIPTIONS %SYSLOG_LEVELS
    $SYSLOG_EMERGENCY $SYSLOG_ALERT $SYSLOG_CRITICAL $SYSLOG_ERROR
    $SYSLOG_WARNING $SYSLOG_NOTICE $SYSLOG_INFO $SYSLOG_DEBUG
    $EMERGENCY $ALERT $CRITICAL $ERROR $WARNING $NOTICE $INFORMATIONAL $DEBUG
    %syslog_values
);

our %EXPORT_TAGS = (
    'all'       => \@EXPORT_OK,
    'constants' => [qw($EMERGENCY $ALERT $CRITICAL $ERROR $WARNING $NOTICE $INFORMATIONAL $DEBUG)],
    'functions' => [qw(get_syslog_level get_syslog_name is_valid_syslog_level is_valid_syslog_number
                      get_syslog_description get_all_syslog_levels get_all_syslog_numbers
                      get_all_syslog_aliases compare_syslog_levels)],
    'hashes'    => [qw(%SYSLOG_LEVELS %SYSLOG_NAMES %SYSLOG_DESCRIPTIONS)],
    'rfc3164'   => [qw($SYSLOG_EMERGENCY $SYSLOG_ALERT $SYSLOG_CRITICAL $SYSLOG_ERROR
                      $SYSLOG_WARNING $SYSLOG_NOTICE $SYSLOG_INFO $SYSLOG_DEBUG)],
);

# Validate module consistency at compile time
BEGIN {
	# Ensure all level numbers have corresponding names
	for my $num (keys %SYSLOG_NAMES) {
		die "Missing description for level $num" unless exists $SYSLOG_DESCRIPTIONS{$num};
	}

	# Ensure all level names resolve to valid numbers
	for my $name (keys %SYSLOG_LEVELS) {
		my $num = $SYSLOG_LEVELS{$name};
		die "Level '$name' maps to invalid number $num" unless exists $SYSLOG_NAMES{$num};
	}
}

=encoding utf-8

=head1 FORMAL SPECIFICATION

    [LEVEL_NAME, LEVEL_NUMBER, DESCRIPTION]

    SyslogLevel ::= 0..7

    ValidLevelNames == {
        emergency, alert, critical, error, warning, notice, info, debug,
        emerg, crit, err, warn, trace, panic, fatal, informational
    }

    LevelMapping == ValidLevelNames ⤇ SyslogLevel
    ReverseLevelMapping == SyslogLevel ⤇ LEVEL_NAME
    DescriptionMapping == SyslogLevel ⤇ DESCRIPTION

    │ dom(LevelMapping) = ValidLevelNames
    │ ran(LevelMapping) = 0..7
    │ dom(ReverseLevelMapping) = 0..7
    │ ran(ReverseLevelMapping) ⊆ ValidLevelNames
    │ dom(DescriptionMapping) = 0..7

    get_syslog_level: LEVEL_NAME → SyslogLevel
    get_syslog_name: SyslogLevel → LEVEL_NAME
    is_valid_syslog_level: LEVEL_NAME → ℙ
    is_valid_syslog_number: ℤ → ℙ

    ∀ name: LEVEL_NAME •
      name ∈ ValidLevelNames ⇔ is_valid_syslog_level(name)

    ∀ num: ℤ •
      num ∈ 0..7 ⇔ is_valid_syslog_number(num)

    ∀ name: ValidLevelNames •
      get_syslog_name(get_syslog_level(name)) ∈ ValidLevelNames

    ∀ level: SyslogLevel •
      get_syslog_level(get_syslog_name(level)) = level

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<https://last9.io/blog/what-are-syslog-levels/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-readonly-values-syslog at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Syslog>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Syslog

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Readonly-Values-Syslog>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Syslog>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Readonly-Values-Syslog>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Readonly::Values::Syslog>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;

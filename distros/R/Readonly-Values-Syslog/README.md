# NAME

Readonly::Values::Syslog - RFC 3164 compliant syslog severity level constants

# VERSION

Version 0.04

# DESCRIPTION

This module provides RFC 3164 compliant syslog severity level constants and
utility functions for syslog level validation and conversion. It offers both
numeric constants and string-based lookups with comprehensive validation.

# SYNOPSIS

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

# RFC 3164 COMPLIANCE

This module implements the syslog severity levels as defined in RFC 3164:

    0  Emergency   - System is unusable
    1  Alert       - Action must be taken immediately
    2  Critical    - Critical conditions
    3  Error       - Error conditions
    4  Warning     - Warning conditions
    5  Notice      - Normal but significant condition
    6  Info        - Informational messages
    7  Debug       - Debug-level messages

# FUNCTIONS

## get\_syslog\_level($level\_name)

Converts a syslog level name (string) to its numeric value.

    my $numeric = get_syslog_level('critical');  # Returns 2
    my $numeric = get_syslog_level('crit');      # Returns 2 (alias)

Dies with a descriptive error if the level name is invalid.

## get\_syslog\_name($level\_number)

Converts a numeric syslog level to its canonical string name.

    my $name = get_syslog_name(2);  # Returns 'critical'

Dies with a descriptive error if the level number is invalid.

## is\_valid\_syslog\_level($level\_name)

Returns true if the given string is a valid syslog level name (including aliases).

    if (is_valid_syslog_level('warning')) {
        # Process the warning
    }

## is\_valid\_syslog\_number($level\_number)

Returns true if the given number is a valid syslog severity level.

    if (is_valid_syslog_number(4)) {
        # Process the warning level (4)
    }

## get\_syslog\_description($level)

Returns the RFC 3164 description for a syslog level. Accepts either numeric
level or string name.

    my $desc = get_syslog_description(2);           # 'Critical conditions'
    my $desc = get_syslog_description('critical');  # 'Critical conditions'

## get\_all\_syslog\_levels()

Returns a list of all valid syslog level names (strings) in severity order.

    my @levels = get_all_syslog_levels();
    # Returns: ('emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug')

## get\_all\_syslog\_numbers()

Returns a list of all valid syslog level numbers in order.

    my @numbers = get_all_syslog_numbers();
    # Returns: (0, 1, 2, 3, 4, 5, 6, 7)

## get\_all\_syslog\_aliases()

Returns a hash reference mapping all aliases to their canonical names.

    my $aliases = get_all_syslog_aliases();
    # $aliases = { 'crit' => 'critical', 'err' => 'error', ... }

## compare\_syslog\_levels($level1, $level2)

Compares two syslog levels and returns -1, 0, or 1 similar to cmp.
Accepts both numeric and string levels.

    my $cmp = compare_syslog_levels('error', 'warning');  # Returns -1 (error < warning)
    my $cmp = compare_syslog_levels(2, 4);               # Returns -1 (critical < warning)

# FORMAL SPECIFICATION

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

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

- [https://last9.io/blog/what-are-syslog-levels/](https://last9.io/blog/what-are-syslog-levels/)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-readonly-values-syslog at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Syslog](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Syslog).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Syslog

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Readonly-Values-Syslog](https://metacpan.org/dist/Readonly-Values-Syslog)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Syslog](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Syslog)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Readonly-Values-Syslog](http://matrix.cpantesters.org/?dist=Readonly-Values-Syslog)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Readonly::Values::Syslog](http://deps.cpantesters.org/?module=Readonly::Values::Syslog)

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

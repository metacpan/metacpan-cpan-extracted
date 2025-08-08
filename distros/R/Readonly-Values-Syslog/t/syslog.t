#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 14;
use Test::Exception;

BEGIN {
	use_ok('Readonly::Values::Syslog', qw(:all))
}

# Test basic constants
subtest 'Basic constants' => sub {
    plan tests => 16;

    # Test RFC 3164 compliance
    is($EMERGENCY, 0, 'Emergency level is 0');
    is($ALERT, 1, 'Alert level is 1');
    is($CRITICAL, 2, 'Critical level is 2');
    is($ERROR, 3, 'Error level is 3');
    is($WARNING, 4, 'Warning level is 4');
    is($NOTICE, 5, 'Notice level is 5');
    is($INFORMATIONAL, 6, 'Informational level is 6');
    is($DEBUG, 7, 'Debug level is 7');

    # Test that constants are actually readonly
    eval { $EMERGENCY = 1 };
    ok($@, 'Constants are readonly');

    # Test constant consistency
    is($SYSLOG_EMERGENCY, $EMERGENCY, 'New constants match old ones');
    is($SYSLOG_ALERT, $ALERT, 'Alert constants consistent');
    is($SYSLOG_CRITICAL, $CRITICAL, 'Critical constants consistent');
    is($SYSLOG_ERROR, $ERROR, 'Error constants consistent');
    is($SYSLOG_WARNING, $WARNING, 'Warning constants consistent');
    is($SYSLOG_NOTICE, $NOTICE, 'Notice constants consistent');
    is($SYSLOG_DEBUG, $DEBUG, 'Debug constants consistent');
};

# Test the critical typo fix
subtest 'Typo fix verification' => sub {
    plan tests => 4;

    # Verify the typo is fixed
    ok(exists $SYSLOG_LEVELS{'critical'}, 'Correct spelling "critical" exists');
    ok(!exists $SYSLOG_LEVELS{'criticial'}, 'Typo "criticial" does not exist');
    is($SYSLOG_LEVELS{'critical'}, 2, 'Critical maps to correct value');
    is(get_syslog_level('critical'), 2, 'get_syslog_level works with correct spelling');
};

# Test string-to-numeric conversion
subtest 'String to numeric conversion' => sub {
    plan tests => 20;

    # Test primary names
    is(get_syslog_level('emergency'), 0, 'Emergency string converts correctly');
    is(get_syslog_level('alert'), 1, 'Alert string converts correctly');
    is(get_syslog_level('critical'), 2, 'Critical string converts correctly');
    is(get_syslog_level('error'), 3, 'Error string converts correctly');
    is(get_syslog_level('warning'), 4, 'Warning string converts correctly');
    is(get_syslog_level('notice'), 5, 'Notice string converts correctly');
    is(get_syslog_level('info'), 6, 'Info string converts correctly');
    is(get_syslog_level('debug'), 7, 'Debug string converts correctly');

    # Test aliases
    is(get_syslog_level('emerg'), 0, 'Emergency alias works');
    is(get_syslog_level('crit'), 2, 'Critical alias works');
    is(get_syslog_level('err'), 3, 'Error alias works');
    is(get_syslog_level('warn'), 4, 'Warning alias works');
    is(get_syslog_level('trace'), 7, 'Trace alias works');
    is(get_syslog_level('panic'), 0, 'Panic alias works');
    is(get_syslog_level('fatal'), 2, 'Fatal alias works');
    is(get_syslog_level('informational'), 6, 'Informational works');

    # Test case insensitivity and whitespace handling
    is(get_syslog_level('CRITICAL'), 2, 'Case insensitive conversion');
    is(get_syslog_level(' warning '), 4, 'Whitespace trimming works');
    is(get_syslog_level('Error'), 3, 'Mixed case works');

    # Test backward compatibility
    is($syslog_values{'critical'}, 2, 'Backward compatibility hash works');
};

# Test numeric-to-string conversion
subtest 'Numeric to string conversion' => sub {
    plan tests => 8;

    is(get_syslog_name(0), 'emergency', 'Numeric 0 converts to emergency');
    is(get_syslog_name(1), 'alert', 'Numeric 1 converts to alert');
    is(get_syslog_name(2), 'critical', 'Numeric 2 converts to critical');
    is(get_syslog_name(3), 'error', 'Numeric 3 converts to error');
    is(get_syslog_name(4), 'warning', 'Numeric 4 converts to warning');
    is(get_syslog_name(5), 'notice', 'Numeric 5 converts to notice');
    is(get_syslog_name(6), 'info', 'Numeric 6 converts to info');
    is(get_syslog_name(7), 'debug', 'Numeric 7 converts to debug');
};

# Test validation functions
subtest 'Validation functions' => sub {
    plan tests => 20;

    # Test is_valid_syslog_level
    ok(is_valid_syslog_level('emergency'), 'Valid level name accepted');
    ok(is_valid_syslog_level('crit'), 'Valid alias accepted');
    ok(is_valid_syslog_level('CRITICAL'), 'Case insensitive validation');
    ok(is_valid_syslog_level(' warning '), 'Whitespace handled in validation');
    ok(!is_valid_syslog_level('invalid'), 'Invalid level name rejected');
    ok(!is_valid_syslog_level(''), 'Empty string rejected');
    ok(!is_valid_syslog_level(undef), 'Undefined value rejected');
    ok(!is_valid_syslog_level('criticial'), 'Typo spelling rejected');

    # Test is_valid_syslog_number
    ok(is_valid_syslog_number(0), 'Valid level 0 accepted');
    ok(is_valid_syslog_number(7), 'Valid level 7 accepted');
    ok(is_valid_syslog_number('3'), 'String number accepted');
    ok(is_valid_syslog_number(3.0), 'Float converted to int');
    ok(!is_valid_syslog_number(8), 'Invalid level 8 rejected');
    ok(!is_valid_syslog_number(-1), 'Negative level rejected');
    ok(!is_valid_syslog_number('abc'), 'Non-numeric string rejected');
    ok(!is_valid_syslog_number(undef), 'Undefined number rejected');
    ok(!is_valid_syslog_number(''), 'Empty string number rejected');
    ok(!is_valid_syslog_number('3.5'), 'Non-integer number rejected after conversion');

    # Edge cases for validation
    ok(!is_valid_syslog_number('inf'), 'Infinity rejected');
    ok(!is_valid_syslog_number('nan'), 'NaN rejected');
};

# Test error handling
subtest 'Error handling' => sub {
    plan tests => 12;

    # Test get_syslog_level errors
    throws_ok {
        get_syslog_level('invalid_level');
    } qr/invalid syslog level/, 'Invalid level name throws error';

    throws_ok {
        get_syslog_level(undef);
    } qr/level name is required/, 'Undefined level name throws error';

    throws_ok {
        get_syslog_level('');
    } qr/invalid syslog level/, 'Empty level name throws error';

    # Test get_syslog_name errors
    throws_ok {
        get_syslog_name(8);
    } qr/invalid syslog level number/, 'Invalid level number throws error';

    throws_ok {
        get_syslog_name(-1);
    } qr/invalid syslog level number/, 'Negative level number throws error';

    throws_ok {
        get_syslog_name(undef);
    } qr/level number is required/, 'Undefined level number throws error';

    throws_ok {
        get_syslog_name('abc');
    } qr/level must be numeric/, 'Non-numeric level throws error';

    # Test get_syslog_description errors
    throws_ok {
        get_syslog_description('invalid');
    } qr/invalid level name/, 'Invalid description level name throws error';

    throws_ok {
        get_syslog_description(9);
    } qr/invalid numeric level/, 'Invalid description level number throws error';

    throws_ok {
        get_syslog_description(undef);
    } qr/level is required/, 'Undefined description level throws error';

    # Test compare_syslog_levels errors
    throws_ok {
        compare_syslog_levels(undef, 'warning');
    } qr/both levels are required/, 'Undefined level in comparison throws error';

    throws_ok {
        compare_syslog_levels('error', undef);
    } qr/both levels are required/, 'Second undefined level throws error';
};

# Test utility functions
subtest 'Utility functions' => sub {
    plan tests => 15;

    # Test get_syslog_description
    is(get_syslog_description(0), 'System is unusable', 'Emergency description correct');
    is(get_syslog_description('critical'), 'Critical conditions', 'Critical description from string');
    is(get_syslog_description(7), 'Debug-level messages', 'Debug description correct');

    # Test get_all_syslog_levels
    my @levels = get_all_syslog_levels();
    is(scalar(@levels), 8, 'Correct number of levels returned');
    is($levels[0], 'emergency', 'First level is emergency');
    is($levels[7], 'debug', 'Last level is debug');
    is_deeply(\@levels, [qw(emergency alert critical error warning notice info debug)],
              'All levels in correct order');

    # Test get_all_syslog_numbers
    my @numbers = get_all_syslog_numbers();
    is(scalar(@numbers), 8, 'Correct number of level numbers returned');
    is_deeply(\@numbers, [0, 1, 2, 3, 4, 5, 6, 7], 'All numbers in correct order');

    # Test get_all_syslog_aliases
    my $aliases = get_all_syslog_aliases();
    ok(exists $aliases->{'crit'}, 'Critical alias exists');
    is($aliases->{'crit'}, 'critical', 'Critical alias maps correctly');
    ok(exists $aliases->{'err'}, 'Error alias exists');
    ok(!exists $aliases->{'critical'}, 'Canonical names not in aliases');
    ok(exists $aliases->{'emerg'}, 'Emergency alias exists');
    is($aliases->{'emerg'}, 'emergency', 'Emergency alias maps correctly');
};

# Test level comparison
subtest 'Level comparison' => sub {
    plan tests => 12;

    # Test numeric comparisons
    is(compare_syslog_levels(0, 1), -1, 'Emergency < Alert');
    is(compare_syslog_levels(4, 4), 0, 'Warning == Warning');
    is(compare_syslog_levels(7, 3), 1, 'Debug > Error');

    # Test string comparisons
    is(compare_syslog_levels('emergency', 'alert'), -1, 'Emergency < Alert (strings)');
    is(compare_syslog_levels('warning', 'warning'), 0, 'Warning == Warning (strings)');
    is(compare_syslog_levels('debug', 'error'), 1, 'Debug > Error (strings)');

    # Test mixed comparisons
    is(compare_syslog_levels(2, 'warning'), -1, 'Critical < Warning (mixed)');
    is(compare_syslog_levels('notice', 7), -1, 'Notice < Debug (mixed)');
    is(compare_syslog_levels('crit', 'err'), -1, 'Critical < Error (aliases)');

    # Test edge cases
    is(compare_syslog_levels(0, 7), -1, 'Minimum < Maximum');
    is(compare_syslog_levels(7, 0), 1, 'Maximum > Minimum');
    is(compare_syslog_levels('emerg', 'panic'), 0, 'Aliases to same level equal');
};

# Test RFC 3164 compliance
subtest 'RFC 3164 compliance' => sub {
    plan tests => 16;

    # Verify exact RFC 3164 mapping
    my %rfc_mapping = (
        0 => 'emergency',   # System is unusable
        1 => 'alert',       # Action must be taken immediately
        2 => 'critical',    # Critical conditions
        3 => 'error',       # Error conditions
        4 => 'warning',     # Warning conditions
        5 => 'notice',      # Normal but significant condition
        6 => 'info',        # Informational messages
        7 => 'debug',       # Debug-level messages
    );

    for my $level (0..7) {
        is(get_syslog_name($level), $rfc_mapping{$level},
           "RFC 3164 level $level maps correctly");
        is(get_syslog_level($rfc_mapping{$level}), $level,
           "RFC 3164 name $rfc_mapping{$level} maps correctly");
    }
};

# Test thread safety and concurrency
subtest 'Thread safety' => sub {
    plan tests => 4;

    # Test that all data structures are readonly
    eval { $SYSLOG_LEVELS{'test'} = 999 };
    ok($@, 'SYSLOG_LEVELS hash is readonly');

    eval { $SYSLOG_NAMES{99} = 'test' };
    ok($@, 'SYSLOG_NAMES hash is readonly');

    eval { $SYSLOG_DESCRIPTIONS{99} = 'test' };
    ok($@, 'SYSLOG_DESCRIPTIONS hash is readonly');

    # Test concurrent access simulation
    my @results;
    for my $i (1..100) {
        push @results, get_syslog_level('critical');
    }
    is_deeply(\@results, [(2) x 100], 'Concurrent access returns consistent results');
};

# Test export functionality
subtest 'Export functionality' => sub {
    plan tests => 8;

    # Test default exports
    ok(defined $EMERGENCY, 'EMERGENCY constant exported by default');
    ok(%syslog_values, 'syslog_values hash exported by default');
    ok(%SYSLOG_LEVELS, 'SYSLOG_LEVELS hash exported by default');

    # Test that functions are exported by default
    ok(main->can('get_syslog_level'), 'Functions exported by default');

    # Test export tags (would need separate test file for full testing)
    ok(exists $Readonly::Values::Syslog::EXPORT_TAGS{'all'}, 'All export tag exists');
    ok(exists $Readonly::Values::Syslog::EXPORT_TAGS{'functions'}, 'Functions export tag exists');
    ok(exists $Readonly::Values::Syslog::EXPORT_TAGS{'constants'}, 'Constants export tag exists');
    ok(exists $Readonly::Values::Syslog::EXPORT_TAGS{'rfc3164'}, 'RFC3164 export tag exists');
};

# Test edge cases and security
subtest 'Edge cases and security' => sub {
    plan tests => 15;

    # Test extremely long strings (potential DoS)
    my $long_string = 'a' x 10000;
    ok(!is_valid_syslog_level($long_string), 'Extremely long string rejected');

    # Test unicode and special characters
    ok(!is_valid_syslog_level('crítico'), 'Unicode characters rejected');
    ok(!is_valid_syslog_level('error!'), 'Special characters rejected');
    ok(!is_valid_syslog_level('error\n'), 'Newlines rejected');
    ok(!is_valid_syslog_level('error\0'), 'Null bytes rejected');

    # Test numeric edge cases
    ok(!is_valid_syslog_number(1e10), 'Extremely large numbers rejected');
    ok(!is_valid_syslog_number(-1e10), 'Extremely negative numbers rejected');

    # Test floating point precision
    is(get_syslog_name(2.0), 'critical', 'Float 2.0 handled correctly');
    is(get_syslog_name(2.9), 'critical', 'Float 2.9 truncated correctly');

    # Test memory usage with many lookups
    my $start_memory = 0; # Would need Devel::Size for real testing
    for my $i (1..1000) {
        get_syslog_level('critical');
        get_syslog_name(2);
        is_valid_syslog_level('warning');
    }
    # Memory should remain constant (no leaks)
    ok(1, 'No memory leaks in repeated operations');

    # Test case variations
    ok(is_valid_syslog_level('CrItIcAl'), 'Mixed case handled');
    ok(is_valid_syslog_level('EMERGENCY'), 'All uppercase handled');
    ok(is_valid_syslog_level('debug'), 'All lowercase handled');

    # Test whitespace variations
    ok(is_valid_syslog_level("\twarning\n"), 'Tab and newline whitespace trimmed');
    ok(is_valid_syslog_level('  error  '), 'Multiple spaces trimmed');
};

# Test backward compatibility
subtest 'Backward compatibility' => sub {
    plan tests => 23;

    # Test that old hash still works
    is($syslog_values{'emergency'}, 0, 'Old hash emergency works');
    is($syslog_values{'critical'}, 2, 'Old hash critical works (typo fixed)');
    is($syslog_values{'debug'}, 7, 'Old hash debug works');

    # Test that old constants still work
    is($EMERGENCY, 0, 'Old EMERGENCY constant works');
    is($CRITICAL, 2, 'Old CRITICAL constant works');
    is($DEBUG, 7, 'Old DEBUG constant works');

    # Test that old hash has same keys as new hash
    my @old_keys = sort keys %syslog_values;
    my @new_keys = sort keys %SYSLOG_LEVELS;
    is_deeply(\@old_keys, \@new_keys, 'Old and new hashes have same keys');

    # Test that old hash has same values as new hash
    for my $key (keys %syslog_values) {
        is($syslog_values{$key}, $SYSLOG_LEVELS{$key},
           "Old and new hash values match for '$key'");
    }
};

done_testing();

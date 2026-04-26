#!/usr/bin/perl -w

# Tests for CHECK_IS_NULL handling.
# When a mock callback returns undef (CHECK_IS_NULL), the file-test OP
# should return undef to the caller, distinct from CHECK_IS_FALSE (0).

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q(:all);

# ---------------------------------------------------------------
# Boolean ops (-e, -f, -d, …) — CHECK_IS_NULL should yield undef
# ---------------------------------------------------------------

{
    note "boolean op: -e with CHECK_IS_NULL";

    my $mock_return;

    mock_file_check(
        '-e' => sub { return $mock_return },
    );

    $mock_return = CHECK_IS_TRUE;
    is( -e "/null-test", 1, "-e CHECK_IS_TRUE returns 1" );

    $mock_return = CHECK_IS_FALSE;
    {
        my $result = -e "/null-test";
        ok( !$result, "-e CHECK_IS_FALSE is false" );
        ok( defined($result), "-e CHECK_IS_FALSE is defined (not undef)" );
    }

    $mock_return = CHECK_IS_NULL;    # undef
    ok( !defined( -e "/null-test" ), "-e CHECK_IS_NULL returns undef" );

    # Ensure it is really undef, not 0 or ''
    $mock_return = CHECK_IS_NULL;
    my $result = -e "/null-test";
    is( $result, undef, "-e CHECK_IS_NULL is literally undef" );

    unmock_all_file_checks();
}

{
    note "boolean op: -f with CHECK_IS_NULL";

    mock_file_check(
        '-f' => sub { return CHECK_IS_NULL },
    );

    my $result = -f "/null-test-f";
    is( $result, undef, "-f CHECK_IS_NULL returns undef" );

    unmock_all_file_checks();
}

{
    note "boolean op: -d with CHECK_IS_NULL";

    mock_file_check(
        '-d' => sub { return CHECK_IS_NULL },
    );

    my $result = -d "/null-test-d";
    is( $result, undef, "-d CHECK_IS_NULL returns undef" );

    unmock_all_file_checks();
}

# ---------------------------------------------------------------
# Integer op (-s) — CHECK_IS_NULL should yield undef, not 0
# ---------------------------------------------------------------

{
    note "integer op: -s with CHECK_IS_NULL";

    my $mock_return;

    mock_file_check(
        '-s' => sub { return $mock_return },
    );

    $mock_return = 42;
    {
        my $result = -s "/null-test-s";
        is( $result, 42, "-s returns the mocked size" );
    }

    $mock_return = 0;
    {
        my $result = -s "/null-test-s";
        is( $result, 0, "-s returns 0 when size is 0" );
    }

    $mock_return = CHECK_IS_NULL;    # undef
    my $result = -s "/null-test-s";
    is( $result, undef, "-s CHECK_IS_NULL returns undef (not 0)" );

    unmock_all_file_checks();
}

# ---------------------------------------------------------------
# NV ops (-M, -A, -C) — CHECK_IS_NULL should yield undef
# ---------------------------------------------------------------

{
    note "NV op: -M with CHECK_IS_NULL";

    my $mock_return;

    mock_file_check(
        '-M' => sub { return $mock_return },
    );

    $mock_return = 1.5;
    ok( defined( -M "/null-test-M" ), "-M returns a defined value for 1.5" );

    $mock_return = CHECK_IS_NULL;    # undef
    my $result = -M "/null-test-M";
    is( $result, undef, "-M CHECK_IS_NULL returns undef" );

    unmock_all_file_checks();
}

{
    note "NV op: -A with CHECK_IS_NULL";

    mock_file_check(
        '-A' => sub { return CHECK_IS_NULL },
    );

    my $result = -A "/null-test-A";
    is( $result, undef, "-A CHECK_IS_NULL returns undef" );

    unmock_all_file_checks();
}

{
    note "NV op: -C with CHECK_IS_NULL";

    mock_file_check(
        '-C' => sub { return CHECK_IS_NULL },
    );

    my $result = -C "/null-test-C";
    is( $result, undef, "-C CHECK_IS_NULL returns undef" );

    unmock_all_file_checks();
}

# ---------------------------------------------------------------
# errno is set when CHECK_IS_NULL is returned
# ---------------------------------------------------------------

{
    note "errno handling with CHECK_IS_NULL";
    local $! = 0;

    mock_file_check(
        '-e' => sub { return CHECK_IS_NULL },
    );

    my $result = -e "/null-errno-test";
    ok( !defined $result, "result is undef" );
    ok( int($!) > 0, "errno is set when CHECK_IS_NULL is returned" );

    unmock_all_file_checks();
}

# ---------------------------------------------------------------
# FALLBACK_TO_REAL_OP still works alongside CHECK_IS_NULL
# ---------------------------------------------------------------

{
    note "FALLBACK_TO_REAL_OP alongside CHECK_IS_NULL";

    mock_file_check(
        '-e' => sub {
            my $f = shift;
            return CHECK_IS_NULL if $f eq '/check-null-missing';
            return FALLBACK_TO_REAL_OP;
        },
    );

    my $null_result = -e '/check-null-missing';
    is( $null_result, undef, "CHECK_IS_NULL path returns undef" );

    my $real_result = -e $0;
    is( $real_result, 1, "FALLBACK_TO_REAL_OP path works for existing file" );

    unmock_all_file_checks();
}

# ---------------------------------------------------------------
# CHECK_IS_NULL constant value
# ---------------------------------------------------------------

{
    note "CHECK_IS_NULL constant";

    ok( !defined CHECK_IS_NULL, "CHECK_IS_NULL is undef" );
}

done_testing;

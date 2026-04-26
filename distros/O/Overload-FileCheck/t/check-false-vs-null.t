#!/usr/bin/perl -w

# Tests the semantic distinction between CHECK_IS_FALSE and CHECK_IS_NULL.
#
# In Perl, file-test operators have two kinds of "false":
#   - Defined false (''): "check failed but file is known" (e.g. -f on a directory)
#   - Undef: "file not found / unknown" (e.g. -e on a nonexistent path)
#
# CHECK_IS_FALSE should map to defined false (FT_RETURNNO),
# CHECK_IS_NULL  should map to undef        (FT_RETURNUNDEF).

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q(:all);

# ---------------------------------------------------------------
# Boolean ops: CHECK_IS_FALSE returns defined false, not undef
# ---------------------------------------------------------------

for my $check (qw( e f d r w x o R W X O z S c b p u g k l t T B )) {
    my $mock_return;

    mock_file_check(
        "-$check" => sub { return $mock_return },
    );

    # CHECK_IS_TRUE: should be defined and true
    $mock_return = CHECK_IS_TRUE;
    {
        my $result = eval qq[ scalar -$check "/check-false-test" ];
        ok( $result, "-$check CHECK_IS_TRUE is true" );
        ok( defined($result), "-$check CHECK_IS_TRUE is defined" );
    }

    # CHECK_IS_FALSE: should be defined but false
    $mock_return = CHECK_IS_FALSE;
    {
        my $result = eval qq[ scalar -$check "/check-false-test" ];
        ok( !$result, "-$check CHECK_IS_FALSE is false" );
        ok( defined($result), "-$check CHECK_IS_FALSE is defined (not undef)" );
    }

    # CHECK_IS_NULL: should be undef
    $mock_return = CHECK_IS_NULL;
    {
        my $result = eval qq[ scalar -$check "/check-false-test" ];
        ok( !$result, "-$check CHECK_IS_NULL is false" );
        ok( !defined($result), "-$check CHECK_IS_NULL is undef" );
    }

    unmock_file_check($check);
}

# ---------------------------------------------------------------
# Practical scenario: defined() distinguishes false from unknown
# ---------------------------------------------------------------

{
    note "Practical: defined(-f) distinguishes false from unknown";

    mock_file_check(
        '-f' => sub {
            my $f = shift;
            return CHECK_IS_TRUE  if $f eq '/known-file';
            return CHECK_IS_FALSE if $f eq '/known-dir';
            return CHECK_IS_NULL;    # unknown
        },
    );

    ok(  defined( -f '/known-file' ), "/known-file: defined (true)" );
    ok(  defined( -f '/known-dir' ),  "/known-dir: defined (false)" );
    ok( !defined( -f '/unknown' ),    "/unknown: undef" );

    ok(  -f '/known-file', "/known-file: true" );
    ok( !-f '/known-dir',  "/known-dir: false" );
    ok( !-f '/unknown',    "/unknown: false (undef)" );

    unmock_file_check('f');
}

done_testing;

#!/usr/bin/perl -w

# Test that -M/-C/-A correctly return -1.0 when a file's timestamp is
# exactly basetime + 86400 (1 day in the future), instead of silently
# falling back to the real OP.
#
# The FALLBACK_TO_REAL_OP sentinel is -1.  Before the fix, the XS handler
# pp_overload_ft_nv checked `SvNV(status) == -1` which collided with the
# legitimate NV value -1.0.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};

my $basetime = Overload::FileCheck::get_basetime();

subtest 'mock_all_from_stat: -M returns -1.0 for mtime 1 day in future' => sub {
    my $mtime_future = $basetime + 86400;

    mock_all_from_stat(sub {
        my ($op, $file) = @_;
        return stat_as_file( mtime => $mtime_future ) if $file eq '/test/future';
        return FALLBACK_TO_REAL_OP;
    });

    my $age = -M '/test/future';
    ok( defined $age, '-M returns a defined value (not undef from fallback)' );
    ok( abs($age - (-1.0)) < 0.01, "-M returns approximately -1.0 (got: $age)" )
        if defined $age;

    unmock_all_file_checks();
    unmock_stat();
};

subtest 'mock_all_from_stat: -A returns -1.0 for atime 1 day in future' => sub {
    my $atime_future = $basetime + 86400;

    mock_all_from_stat(sub {
        my ($op, $file) = @_;
        return stat_as_file( atime => $atime_future ) if $file eq '/test/future';
        return FALLBACK_TO_REAL_OP;
    });

    my $age = -A '/test/future';
    ok( defined $age, '-A returns a defined value (not undef from fallback)' );
    ok( abs($age - (-1.0)) < 0.01, "-A returns approximately -1.0 (got: $age)" )
        if defined $age;

    unmock_all_file_checks();
    unmock_stat();
};

subtest 'mock_all_from_stat: -C returns -1.0 for ctime 1 day in future' => sub {
    my $ctime_future = $basetime + 86400;

    mock_all_from_stat(sub {
        my ($op, $file) = @_;
        return stat_as_file( ctime => $ctime_future ) if $file eq '/test/future';
        return FALLBACK_TO_REAL_OP;
    });

    my $age = -C '/test/future';
    ok( defined $age, '-C returns a defined value (not undef from fallback)' );
    ok( abs($age - (-1.0)) < 0.01, "-C returns approximately -1.0 (got: $age)" )
        if defined $age;

    unmock_all_file_checks();
    unmock_stat();
};

subtest 'mock_all_from_stat: FALLBACK still works for non-mocked files' => sub {
    mock_all_from_stat(sub {
        my ($op, $file) = @_;
        return stat_as_file( mtime => $basetime ) if $file eq '/test/now';
        return FALLBACK_TO_REAL_OP;
    });

    # /nonexistent should fall back to real stat => undef
    my $age = -M '/nonexistent/path/should/not/exist';
    ok( !defined $age, 'FALLBACK_TO_REAL_OP still delegates to real OP' );

    # mocked file should return ~0 days
    my $now_age = -M '/test/now';
    ok( defined $now_age, '-M returns defined for mocked file' );
    ok( abs($now_age) < 0.01, "-M returns approximately 0 (got: $now_age)" )
        if defined $now_age;

    unmock_all_file_checks();
    unmock_stat();
};

subtest 'direct mock_file_check: -M FALLBACK_TO_REAL_OP still works' => sub {
    mock_file_check( '-M' => sub {
        my ($file) = @_;
        return 42.5 if $file eq '/test/custom';
        return FALLBACK_TO_REAL_OP;
    });

    my $age = -M '/test/custom';
    ok( defined $age, '-M returns defined for mocked file' );
    ok( abs($age - 42.5) < 0.01, "-M returns 42.5 (got: $age)" )
        if defined $age;

    my $real = -M '/nonexistent/direct/mock/fallback';
    ok( !defined $real, 'FALLBACK_TO_REAL_OP works for direct -M mock' );

    unmock_file_check('-M');
};

subtest 'mock_all_from_stat: other NV values pass through correctly' => sub {
    mock_all_from_stat(sub {
        my ($op, $file) = @_;
        if ( $file eq '/test/past' ) {
            return stat_as_file( mtime => $basetime - 2 * 86400 );  # 2 days ago
        }
        if ( $file eq '/test/far_future' ) {
            return stat_as_file( mtime => $basetime + 5 * 86400 );  # 5 days future
        }
        return FALLBACK_TO_REAL_OP;
    });

    my $past = -M '/test/past';
    ok( defined $past, '-M defined for 2 days ago' );
    ok( abs($past - 2.0) < 0.01, "-M returns ~2.0 (got: $past)" ) if defined $past;

    my $far = -M '/test/far_future';
    ok( defined $far, '-M defined for 5 days in future' );
    ok( abs($far - (-5.0)) < 0.01, "-M returns ~-5.0 (got: $far)" ) if defined $far;

    unmock_all_file_checks();
    unmock_stat();
};

done_testing;

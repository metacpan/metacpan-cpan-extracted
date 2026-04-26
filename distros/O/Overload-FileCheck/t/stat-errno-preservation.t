#!/usr/bin/perl -w

# Test that errno ($!) is preserved through XS scope cleanup
# after _check() sets it for failed stat/lstat/file-check operations.
#
# The XS functions _overload_ft_ops() and _overload_ft_stat() call
# FREETMPS/LEAVE after the Perl _check() function returns. Without
# saving/restoring errno, this cleanup can clobber $! values set by
# the mock callback or by _check()'s default errno logic.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};
use Errno ();

my $missing = '/stat/errno/missing';
my $exists  = '/stat/errno/exists';

# --- Test with mock_all_from_stat (the -from-stat path) ---

subtest 'errno preserved through stat via mock_all_from_stat' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( $file eq $exists ) {
                return stat_as_file();
            }
            if ( $file eq $missing ) {
                $! = Errno::ENOENT();
                return 0;    # falsy = file not found
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    subtest '-e on missing file sets ENOENT' => sub {
        $! = 0;
        my $check = -e $missing;
        ok( !$check, '-e returns false for missing mock' );
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -e on missing file' );
    };

    subtest '-f on missing file sets ENOENT' => sub {
        $! = 0;
        my $check = -f $missing;
        ok( !$check, '-f returns false for missing mock' );
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -f on missing file' );
    };

    subtest 'stat on missing file preserves errno' => sub {
        $! = 0;
        my @st = stat($missing);
        is( scalar @st, 0, 'stat returns empty list for missing mock' );
        is( int($!), Errno::ENOENT(), '$! is ENOENT after stat on missing file' );
    };

    subtest 'lstat on missing file preserves errno' => sub {
        $! = 0;
        my @st = lstat($missing);
        is( scalar @st, 0, 'lstat returns empty list for missing mock' );
        is( int($!), Errno::ENOENT(), '$! is ENOENT after lstat on missing file' );
    };

    subtest '-e on existing file does not set errno' => sub {
        $! = 0;
        my $check = -e $exists;
        ok( $check, '-e returns true for existing mock' );
        is( int($!), 0, '$! is not set after successful -e' );
    };

    unmock_all_file_checks();
};

# --- Test with custom errno values ---

subtest 'custom errno preserved through file check' => sub {
    mock_file_check(
        '-e' => sub {
            my $f = shift;
            if ( $f eq $missing ) {
                $! = Errno::EACCES();
                return CHECK_IS_FALSE;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    $! = 0;
    my $check = -e $missing;
    ok( !$check, '-e returns false' );
    is( int($!), Errno::EACCES(), '$! preserves custom EACCES through XS cleanup' );

    unmock_all_file_checks();
};

# --- Test default errno when callback doesn't set one ---

subtest 'default ENOENT set when callback returns false without setting errno' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( $file eq $missing ) {
                # Don't set $!, let _check() set the default
                return 0;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    $! = 0;
    my $check = -e $missing;
    ok( !$check, '-e returns false' );
    is( int($!), Errno::ENOENT(), '$! gets default ENOENT when callback omits errno' );

    unmock_all_file_checks();
};

done_testing;

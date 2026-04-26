#!/usr/bin/perl -w

# Test that errno ($!) is preserved through pp_overload_ft_int handler
# for the -s operator.
#
# The helper _overload_ft_ops() saves/restores errno around
# FREETMPS/LEAVE, but the handler itself can clobber errno through
# sv_setiv() or FT_RETURN_TARG before returning.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};
use Errno ();

my $missing = '/int/errno/missing';
my $exists  = '/int/errno/exists';

subtest 'errno preserved through -s via mock_all_from_stat' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( $file eq $exists ) {
                return stat_as_file( size => 42 );
            }
            if ( $file eq $missing ) {
                $! = Errno::ENOENT();
                return 0;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    subtest '-s on existing file returns size' => sub {
        $! = 0;
        my $size = -s $exists;
        is( $size, 42, '-s returns mocked file size' );
        is( int($!), 0, '$! is not set after successful -s' );
    };

    subtest '-s on missing file preserves ENOENT' => sub {
        $! = 0;
        my $size = -s $missing;
        ok( !$size, '-s returns false for missing mock' );
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -s on missing file' );
    };

    unmock_all_file_checks();
};

subtest 'custom errno preserved through -s mock_file_check' => sub {
    mock_file_check(
        '-s' => sub {
            my $f = shift;
            if ( $f eq $missing ) {
                $! = Errno::EACCES();
                return CHECK_IS_FALSE;
            }
            if ( $f eq $exists ) {
                return 1024;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    subtest '-s returns size with custom mock' => sub {
        $! = 0;
        my $size = -s $exists;
        is( $size, 1024, '-s returns mocked size' );
        is( int($!), 0, '$! is not set after successful -s' );
    };

    subtest '-s preserves custom EACCES' => sub {
        $! = 0;
        my $size = -s $missing;
        ok( !$size, '-s returns false' );
        is( int($!), Errno::EACCES(), '$! preserves custom EACCES through int handler' );
    };

    unmock_all_file_checks();
};

subtest 'auto-errno for int op returning CHECK_IS_FALSE without setting $!' => sub {
    # GH #62: when a -s mock returns CHECK_IS_FALSE (0) without setting $!,
    # _check() should auto-set a default errno (ENOENT), same as boolean ops.
    mock_file_check(
        '-s' => sub {
            my $f = shift;
            if ( $f eq $missing ) {
                return CHECK_IS_FALSE;    # no explicit $! set
            }
            if ( $f eq $exists ) {
                return 512;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    subtest '-s returns size normally' => sub {
        $! = 0;
        my $size = -s $exists;
        is( $size, 512, '-s returns mocked size' );
        is( int($!), 0, '$! is not set after successful -s' );
    };

    subtest '-s with CHECK_IS_FALSE auto-sets ENOENT' => sub {
        $! = 0;
        my $size = -s $missing;
        ok( !$size, '-s returns false' );
        is( int($!), Errno::ENOENT(), '$! auto-set to ENOENT when mock returns CHECK_IS_FALSE without setting $!' );
    };

    unmock_all_file_checks();
};

done_testing;

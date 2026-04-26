#!/usr/bin/perl -w

# Test that errno ($!) is preserved through pp_overload_ft_nv handler
# for -M, -A, -C operators.
#
# The helper _overload_ft_ops_sv() saves/restores errno around
# FREETMPS/LEAVE, but the handler itself can clobber errno through
# sv_setnv()/sv_setiv() or FT_RETURN_TARG before returning.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};
use Errno ();

my $missing = '/nv/errno/missing';
my $exists  = '/nv/errno/exists';

subtest 'errno preserved through -M via mock_all_from_stat' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( $file eq $exists ) {
                return stat_as_file();
            }
            if ( $file eq $missing ) {
                $! = Errno::ENOENT();
                return 0;
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    subtest '-M on missing file preserves ENOENT' => sub {
        $! = 0;
        my $age = -M $missing;
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -M on missing file' );
    };

    subtest '-A on missing file preserves ENOENT' => sub {
        $! = 0;
        my $age = -A $missing;
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -A on missing file' );
    };

    subtest '-C on missing file preserves ENOENT' => sub {
        $! = 0;
        my $age = -C $missing;
        is( int($!), Errno::ENOENT(), '$! is ENOENT after -C on missing file' );
    };

    subtest '-M on existing file does not set errno' => sub {
        $! = 0;
        my $age = -M $exists;
        is( int($!), 0, '$! is not set after successful -M' );
    };

    unmock_all_file_checks();
};

subtest 'custom errno preserved through -M mock_file_check' => sub {
    mock_file_check(
        '-M' => sub {
            my $f = shift;
            if ( $f eq $missing ) {
                $! = Errno::EACCES();
                return 0.5;    # return an NV value, not FALLBACK
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    $! = 0;
    my $age = -M $missing;
    is( int($!), Errno::EACCES(), '$! preserves custom EACCES through NV handler' );

    unmock_all_file_checks();
};

done_testing;

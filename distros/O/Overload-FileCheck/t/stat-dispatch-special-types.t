#!/usr/bin/perl -w

# Test that _check_from_stat uses stat (not lstat) for -p, -S, -b, -c checks,
# matching real Perl semantics where these operators follow symlinks.
#
# Before this fix, -p/-S/-b/-c used lstat, so mocking a symlink that points
# to a socket (for example) would incorrectly fail -S because lstat sees
# symlink mode bits, not socket mode bits.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw(S_IFIFO);
use Overload::FileCheck q{:all};

my $mock_path = '/test/special-file';

subtest '-p/-S/-b/-c dispatch stat, not lstat' => sub {
    my @types_seen;

    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( defined $file && $file eq $mock_path ) {
                push @types_seen, $type;
                return stat_as_socket();
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    for my $check (qw( p S b c )) {
        @types_seen = ();
        # Just trigger the check to verify the stat_or_lstat argument
        eval "no warnings; -$check '$mock_path'";
        is( \@types_seen, ['stat'], "-$check dispatches stat, not lstat" );
    }

    unmock_all_file_checks();
};

subtest '-S detects socket through symlink mock' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            return FALLBACK_TO_REAL_OP unless defined $file && $file eq $mock_path;

            if ( $type eq 'lstat' ) {
                # lstat sees the symlink itself
                return stat_as_symlink();
            }
            # stat follows the symlink and sees the socket
            return stat_as_socket();
        }
    );

    ok( -S $mock_path, '-S returns true for symlink-to-socket (follows symlink via stat)' );
    ok( !-f $mock_path, '-f returns false for socket' );

    unmock_all_file_checks();
};

subtest '-p detects pipe through symlink mock' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            return FALLBACK_TO_REAL_OP unless defined $file && $file eq $mock_path;

            if ( $type eq 'lstat' ) {
                return stat_as_symlink();
            }
            return [ 0, 0, S_IFIFO | 0644, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        }
    );

    ok( -p $mock_path, '-p returns true for symlink-to-pipe (follows symlink via stat)' );

    unmock_all_file_checks();
};

subtest '-b detects block device through symlink mock' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            return FALLBACK_TO_REAL_OP unless defined $file && $file eq $mock_path;

            if ( $type eq 'lstat' ) {
                return stat_as_symlink();
            }
            return stat_as_block();
        }
    );

    ok( -b $mock_path, '-b returns true for symlink-to-block-device (follows symlink via stat)' );

    unmock_all_file_checks();
};

subtest '-c detects char device through symlink mock' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            return FALLBACK_TO_REAL_OP unless defined $file && $file eq $mock_path;

            if ( $type eq 'lstat' ) {
                return stat_as_symlink();
            }
            return stat_as_chr();
        }
    );

    ok( -c $mock_path, '-c returns true for symlink-to-char-device (follows symlink via stat)' );

    unmock_all_file_checks();
};

subtest '-l still uses lstat correctly' => sub {
    my @types_seen;

    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            return FALLBACK_TO_REAL_OP unless defined $file && $file eq $mock_path;
            push @types_seen, $type;

            if ( $type eq 'lstat' ) {
                return stat_as_symlink();
            }
            return stat_as_file();
        }
    );

    @types_seen = ();
    ok( -l $mock_path, '-l returns true for symlink' );
    is( \@types_seen, ['lstat'], '-l dispatches lstat, not stat' );

    unmock_all_file_checks();
};

done_testing;

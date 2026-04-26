#!/usr/bin/perl -w

# Test that _check_from_stat uses stat (not lstat) for -u, -g, -k checks,
# matching real Perl semantics where these operators follow symlinks.
# See GH #61.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};

my $suid_file = '/test/suid-binary';

subtest 'mock_all_from_stat dispatches stat (not lstat) for -u/-g/-k' => sub {
    my @stat_types_seen;

    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            push @stat_types_seen, $type if defined $file && $file eq $suid_file;

            if ( defined $file && $file eq $suid_file ) {
                # Return a stat array with setuid bit set (mode 0104755)
                return stat_as_file( perms => 04755 );
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    @stat_types_seen = ();
    my $result = -u $suid_file;
    ok( $result, '-u returns true for setuid file' );
    is( \@stat_types_seen, ['stat'], '-u dispatches stat, not lstat' );

    @stat_types_seen = ();
    $result = -g $suid_file;
    ok( !$result, '-g returns false (no setgid bit)' );
    is( \@stat_types_seen, ['stat'], '-g dispatches stat, not lstat' );

    @stat_types_seen = ();
    $result = -k $suid_file;
    ok( !$result, '-k returns false (no sticky bit)' );
    is( \@stat_types_seen, ['stat'], '-k dispatches stat, not lstat' );

    unmock_all_file_checks();
};

subtest 'setgid and sticky bits detected correctly' => sub {
    mock_all_from_stat(
        sub {
            my ( $type, $file ) = @_;
            if ( defined $file && $file eq '/test/setgid' ) {
                return stat_as_file( perms => 02755 );
            }
            if ( defined $file && $file eq '/test/sticky' ) {
                return stat_as_directory( perms => 01755 );
            }
            return FALLBACK_TO_REAL_OP;
        }
    );

    ok( -g '/test/setgid', '-g detects setgid bit via stat' );
    ok( -k '/test/sticky', '-k detects sticky bit via stat' );

    unmock_all_file_checks();
};

done_testing;

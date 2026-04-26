#!/usr/bin/perl -w

# Verify that the -B handler in _check_from_stat does not re-enter the
# mock system by calling "-d $f_or_fh".  Before the fix, the -B handler
# triggered a second stat callback through the mocked -d operator,
# wasting a round-trip and risking side-effect divergence.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q(:all);

my $stat_call_count = 0;

# Track how many times the stat callback is invoked per -B check.
mock_all_from_stat(
    sub {
        my ( $op, $file ) = @_;

        return FALLBACK_TO_REAL_OP unless defined $file;
        return FALLBACK_TO_REAL_OP unless $file =~ m{^MOCK/};

        $stat_call_count++;

        if ( $file eq 'MOCK/regular-file' ) {
            return stat_as_file( size => 100 );
        }

        if ( $file eq 'MOCK/a-directory' ) {
            return stat_as_directory();
        }

        return [];    # file not found
    }
);

# -B on a mocked regular file: stat callback should be called exactly once
$stat_call_count = 0;
my $result = -B 'MOCK/regular-file';
is $stat_call_count, 1, '-B on regular file triggers stat callback exactly once (no double-dispatch)';

# -B on a mocked directory: stat callback should be called exactly once
# and -B should return true (directories are "binary" in Perl)
$stat_call_count = 0;
$result = -B 'MOCK/a-directory';
is $stat_call_count, 1, '-B on directory triggers stat callback exactly once (no double-dispatch)';
ok $result, '-B on directory returns true';

# -B on a non-existent mocked file: stat callback should be called exactly once
$stat_call_count = 0;
$result = -B 'MOCK/no-such-file';
is $stat_call_count, 1, '-B on non-existent file triggers stat callback exactly once';

unmock_all_file_checks();
unmock_stat();

done_testing;

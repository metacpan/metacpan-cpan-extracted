#!/usr/bin/perl -w

# Regression test for https://github.com/cpan-authors/Overload-FileCheck/issues/63
# _normalize_stat_result must accept bare keys (without st_ prefix) in the same
# way that the stat_as_* helpers do via _stat_for.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw(mock_stat unmock_all_file_checks FALLBACK_TO_REAL_OP);

sub fresh_stat { [ (0) x Overload::FileCheck::STAT_T_MAX() ] }

# Install a stat mock that returns hash refs to drive _normalize_stat_result.
mock_stat(
    sub {
        my ( $opname, $f ) = @_;

        # bare key only
        return { dev => 42 } if $f eq 'bare.dev';

        # multiple bare keys
        return { dev => 7, size => 512, mtime => 1600000000 }
            if $f eq 'bare.multi';

        # mixed: some have st_ prefix, some bare
        return { st_dev => 3, size => 256, mode => 0100644 }
            if $f eq 'bare.mixed';

        # st_-prefixed keys must still work
        return { st_dev => 99, st_size => 1024 } if $f eq 'st.prefix';

        # uppercase bare key
        return { DEV => 5 } if $f eq 'bare.upper';

        # uppercase st_-prefixed key
        return { ST_SIZE => 8192 } if $f eq 'st.upper';

        return FALLBACK_TO_REAL_OP();
    }
);

# --- bare.dev ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_DEV() ] = 42;
    is [ stat('bare.dev') ], $expect, "bare key 'dev' accepted";
}

# --- bare.multi ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_DEV() ]   = 7;
    $expect->[ Overload::FileCheck::ST_SIZE() ]  = 512;
    $expect->[ Overload::FileCheck::ST_MTIME() ] = 1600000000;
    is [ stat('bare.multi') ], $expect, "multiple bare keys accepted";
}

# --- bare.mixed ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_DEV() ]  = 3;
    $expect->[ Overload::FileCheck::ST_SIZE() ] = 256;
    $expect->[ Overload::FileCheck::ST_MODE() ] = 0100644;
    is [ stat('bare.mixed') ], $expect, "mixed bare and st_-prefixed keys accepted";
}

# --- st.prefix (existing behaviour must not regress) ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_DEV() ]  = 99;
    $expect->[ Overload::FileCheck::ST_SIZE() ] = 1024;
    is [ stat('st.prefix') ], $expect, "st_-prefixed keys still work";
}

# --- bare.upper (case-insensitive bare key) ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_DEV() ] = 5;
    is [ stat('bare.upper') ], $expect, "uppercase bare key 'DEV' accepted";
}

# --- st.upper (case-insensitive st_-prefixed key) ---
{
    my $expect = fresh_stat();
    $expect->[ Overload::FileCheck::ST_SIZE() ] = 8192;
    is [ stat('st.upper') ], $expect, "uppercase prefixed key 'ST_SIZE' accepted";
}

unmock_all_file_checks();
done_testing;

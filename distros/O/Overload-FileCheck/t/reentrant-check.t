#!/usr/bin/perl

# Test that _check() is re-entrant safe.
# When a mock callback triggers another mocked file test, the outer
# call's $_last_call_for must not be corrupted.  See GH #68.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q/:all/;

# Track which filenames each mock callback receives.
my @ftis_files;     # -e callback
my @ftfile_files;   # -f callback
my @ftdir_files;    # -d callback

# --- Test 1: Inner call does not corrupt outer stacked-op filename ---

mock_file_check(
    '-e' => sub {
        my ($file) = @_;
        push @ftis_files, $file;
        return CHECK_IS_TRUE;
    }
);

mock_file_check(
    '-f' => sub {
        my ($file) = @_;
        push @ftfile_files, $file;

        # Re-entrant call: trigger another mocked file test inside
        # the callback.  This will call _check() recursively.
        my $inner = -e "/inner/file";

        return CHECK_IS_TRUE;
    }
);

mock_file_check(
    '-d' => sub {
        my ($file) = @_;
        push @ftdir_files, $file;
        return CHECK_IS_TRUE;
    }
);

# Run the sequence: -f on outer, which triggers -e on inner inside the
# callback, then -d _ (stacked) should still see the outer filename.
@ftis_files  = ();
@ftfile_files = ();
@ftdir_files  = ();

ok( -f "/outer/file",  "-f /outer/file" );
ok( -d _,              "-d _ (stacked after -f)" );

is \@ftfile_files, ["/outer/file"], "-f callback received /outer/file";
is \@ftis_files,   ["/inner/file"], "-e callback received /inner/file (re-entrant)";
is \@ftdir_files,  ["/outer/file"], "-d _ received /outer/file (not corrupted by re-entrant call)";

unmock_all_file_checks();

# --- Test 2: mock_all_from_stat with re-entrant file test ---

my @stat_files;
my $reentrant_result;

mock_all_from_stat(
    sub {
        my ( $stat_or_lstat, $file ) = @_;
        push @stat_files, $file;

        # The mock_all_from_stat callback may itself trigger a
        # separate file test in complex scenarios.  Simulate by
        # checking if the file is /trigger — if so, do a nested -e.
        if ( defined $file && $file eq "/trigger" ) {
            $reentrant_result = -e "/nested";
        }

        return stat_as_file( size => 42 );
    }
);

@stat_files       = ();
$reentrant_result = undef;

# -e "/trigger" will call the mock, which will re-enter via -e "/nested"
ok( -e "/trigger", "-e /trigger (triggers re-entrant call)" );

# After -e "/trigger", a stacked -s _ should see "/trigger", not "/nested"
is( -s _, 42, "-s _ returns the stat size from /trigger context" );

# Verify the re-entrant call happened
ok( defined $reentrant_result, "re-entrant -e /nested was called" );

# Verify the order of stat calls: /trigger first, then /nested from
# re-entrancy.  The stacked -s _ reuses the cached stat buffer from
# the /trigger call so it does not trigger a new callback.
is \@stat_files, ["/trigger", "/nested"],
    "stat callback order: /trigger, /nested (re-entrant)";

unmock_all_file_checks();

done_testing;

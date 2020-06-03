#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;
use re '/msx';

our $VERSION = '9999';

use File::Basename;
use File::Temp;
use Rex::Commands::File;
use Rex::Hook::File::Diff;
use Test2::V0 0.000071;
use Test::Output 0.03;

plan tests => 2;

## no critic ( ProhibitComplexRegexes )

subtest 'quick file lifecycle' => sub {
    my $file             = File::Temp->new()->filename();
    my $rex_tmp_filename = Rex::Hook::File::Diff::get_rex_temp_file_path($file);

    my @tests = (
        {
            scenario        => 'create file with content',
            coderef         => sub { file $file, content => '1' },
            expected_output => qr{
              \A                                    # start of output
              \QDiff for: \E$file\n                 # leading message
              \Q--- \E/dev/null(\s+.*?)?\n          # header for original file
              \Q+++ \E$rex_tmp_filename(\s+.*?)?\n  # header for new file
              \Q@@ -0,0 +1 @@\E\n                   # hunk
              \Q+1\E\n                              # added line
              \Z                                    # end of output
            },
        },
        {
            scenario        => 'remove file with content',
            coderef         => sub { file $file, ensure => 'absent' },
            expected_output => qr{
              \A                            # start of output
              \QDiff for: \E$file\n         # leading message
              \Q--- \E$file(\s+.*?)?\n      # header for original file
              \Q+++ \E/dev/null(\s+.*?)?\n  # header for new file
              \Q@@ -1 +0,0 @@\E\n           # hunk
              \Q-1\E\n                      # added line
              \Z                            # end of output
            },
        },
    );

    run_tests(@tests);
};

subtest 'full file lifecycle' => sub {
    my $file             = File::Temp->new()->filename();
    my $rex_tmp_filename = Rex::Hook::File::Diff::get_rex_temp_file_path($file);

    my @tests = (
        {
            scenario        => 'create empty file',
            coderef         => sub { file $file, ensure => 'present' },
            expected_output => qr{\A\Z},
        },
        {
            scenario        => 'add line to file',
            coderef         => sub { file $file, content => '1' },
            expected_output => qr{
              \A                                    # start of output
              \QDiff for: \E$file\n                 # leading message
              \Q--- \E$file(\s+.*?)?\n              # header for original file
              \Q+++ \E$rex_tmp_filename(\s+.*?)?\n  # header for new file
              \Q@@ -0,0 +1 @@\E\n                   # hunk
              \Q+1\E\n                              # added line
              \Z                                    # end of output
            },
        },
        {
            scenario        => 'modify line in file',
            coderef         => sub { file $file, content => '2' },
            expected_output => qr{
              \A                                    # start of output
              \QDiff for: \E$file\n                 # leading message
              \Q--- \E$file(\s+.*?)?\n              # header for original file
              \Q+++ \E$rex_tmp_filename(\s+.*?)?\n  # header for new file
              \Q@@ -1 +1 @@\E\n                     # hunk
              \Q-1\E\n                              # removed line
              \Q+2\E\n                              # added line
              \Z                                    # end of output
            },
        },
        {
            scenario        => 'remove line from file',
            coderef         => sub { file $file, content => q() },
            expected_output => qr{
              \A                                    # start of output
              \QDiff for: \E$file\n                 # leading message
              \Q--- \E$file(\s+.*?)?\n              # header for original file
              \Q+++ \E$rex_tmp_filename(\s+.*?)?\n  # header for new file
              \Q@@ -1 +0,0 @@\E\n                   # hunk
              \Q-2\E\n                              # removed line
              \Z                                    # end of output
            },
        },
        {
            scanario        => 'remove empty file',
            coderef         => sub { file $file, ensure => 'absent' },
            expected_output => qr{\A\Z},
        },
    );

    run_tests(@tests);
};

sub run_tests {
    my @tests = @_;

    for my $test (@tests) {
        stdout_like(
            \&{ $test->{coderef} },
            $test->{expected_output},
            $test->{scenario},
        );
    }

    return;
}

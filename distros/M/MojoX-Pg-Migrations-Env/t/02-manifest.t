#!/usr/bin/env perl
# ABOUTME: Test that MANIFEST file is complete and accurate.
# ABOUTME: Verifies all source files (.pm, .t, bin/*) are listed in MANIFEST.

use strict;
use warnings;

use Test::More;
use File::Find;
use File::Spec;

plan skip_all => 'set AUTHOR_TESTING to enable this test' unless $ENV{AUTHOR_TESTING};

# Read MANIFEST file
my $manifest_file = 'MANIFEST';
ok( -f $manifest_file, 'MANIFEST file exists' );

my %manifest_files;
open my $fh, '<', $manifest_file or die "Cannot open $manifest_file: $!";
while ( my $line = <$fh> ) {
    chomp $line;

    # Skip empty lines and comments
    next if $line =~ /^\s*$/;
    next if $line =~ /^\s*#/;

    # Extract filename (first column, tab or space separated)
    my ($file) = split /\s+/, $line, 2;
    $manifest_files{$file} = 1;
}
close $fh;

# Read MANIFEST.SKIP patterns
my @skip_patterns;
my $skip_file = 'MANIFEST.SKIP';
if ( -f $skip_file ) {
    open my $skip_fh, '<', $skip_file or die "Cannot open $skip_file: $!";
    while ( my $line = <$skip_fh> ) {
        chomp $line;

        # Skip empty lines and comments
        next if $line =~ /^\s*$/;
        next if $line =~ /^\s*#/;

        push @skip_patterns, $line;
    }
    close $skip_fh;
}

# Helper function to check if a file should be skipped
sub should_skip
{
    my ($file) = @_;
    for my $pattern (@skip_patterns) {

        # Patterns can be regexes
        return 1 if $file =~ /$pattern/;
    }
    return 0;
}

# Get all files tracked by git
my @git_files;
if ( -d '.git' ) {
    @git_files = `git ls-files`;
    chomp @git_files;
} else {

    # If not in a git repo, fall back to file system search
    find(
        sub {
            return unless -f $_;
            return if /~$/;
            return if /^#/;
            return if /\.swp$/;
            my $path = File::Spec->abs2rel($File::Find::name);
            push @git_files, $path;
        },
        'lib',
        't'
    );
}

# Filter for files that should be in MANIFEST (.pm, .t, bin/*)
my @expected_files;
for my $file (@git_files) {

    # Skip files that match MANIFEST.SKIP patterns
    next if should_skip($file);

    # Include .pm and .t files
    if ( $file =~ /\.(pm|t)$/ ) {
        push @expected_files, $file;
        next;
    }

    # Include all files in bin/ directory
    if ( $file =~ m{^bin/} ) {
        push @expected_files, $file;
        next;
    }
}

# Sort for consistent ordering
@expected_files = sort @expected_files;

# Check each expected file is in MANIFEST
my @missing_files;
for my $file (@expected_files) {
    unless ( $manifest_files{$file} ) {
        push @missing_files, $file;
    }
}

# Report results
is( scalar(@missing_files), 0, 'All source files are listed in MANIFEST' )
  or diag( "Missing files from MANIFEST:\n  " . join( "\n  ", @missing_files ) );

# Also check for files in MANIFEST that don't exist
my @phantom_files;
for my $file ( sort keys %manifest_files ) {

    # Skip special entries
    next if $file eq 'MANIFEST';
    next if $file eq 'MANIFEST.SKIP';

    # Skip non-code files that we're not checking
    next unless $file =~ /\.(pm|t|pl|sh)$/;

    unless ( -f $file ) {
        push @phantom_files, $file;
    }
}

is( scalar(@phantom_files), 0, 'No phantom files in MANIFEST' )
  or diag( "Files in MANIFEST that don't exist:\n  " . join( "\n  ", @phantom_files ) );

done_testing;

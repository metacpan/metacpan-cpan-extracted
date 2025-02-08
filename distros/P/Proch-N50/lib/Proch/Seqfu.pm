package Proch::Seqfu;
#ABSTRACT: SeqFu utilities

use strict;
use warnings;
use 5.014;
use Carp qw(confess);
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use base 'Exporter';

# Version and configuration
our $VERSION     = '1.7.0';
our $fu_linesize = 0;
our $fu_verbose  = 0;




# Explicitly declare exports
our @EXPORT = qw(
    rc 
    fu_printfasta 
    fu_printfastq 
    verbose 
    has_seqfu 
    seqfu_version
    is_seq
);

our @EXPORT_OK = qw($fu_linesize $fu_verbose);

# Function to check SeqFu version
sub seqfu_version {
    my $cmd = '';
    
    eval {
        my $path = $ENV{PATH};
        $path =~ /^(.+)$/;  # Untaint PATH by capturing
        local $ENV{PATH} = $1;
        $cmd = qx(seqfu version 2>/dev/null);
        chomp($cmd);
    };
    
    return -2 if $@;
    return $cmd if $cmd =~ /^(\d+)\.(\d+)(?:\.(\d+))?$/;
    return "-$cmd";
}

# Function to check if SeqFu is available
sub has_seqfu {
    my $ver = seqfu_version();
    return 0 if $ver =~ /^-/;        # Not installed/error
    return 1 if length($ver) > 0;     # Valid version found
    return undef;                     # Unknown state
}

# Validate sequence string
sub is_seq {
    my $string = $_[0];
    return 0 unless defined $string;
    return $string !~ /[^ACGTRYSWKMBDHVNU]/i;
}

# Get reverse complement
sub rc {
    my $sequence = reverse($_[0]);
    return unless is_seq($sequence);
    
    if ($sequence =~ /U/i) {
        $sequence =~ tr/ACGURYSWKMBDHVacguryswkmbdhv/UGCAYRSWMKVHDBugcayrswmkvhdb/;
    } else {
        $sequence =~ tr/ACGTRYSWKMBDHVacgtryswkmbdhv/TGCAYRSWMKVHDBtgcayrswmkvhdb/;
    }
    return $sequence;
}

# Print verbose messages
sub verbose {
    say STDERR " - ", $_[0] if $fu_verbose;
}

# Print FASTA format
sub fu_printfasta {
    my ($name, $comment, $seq) = @_;
    confess "Error: Name parameter required" unless defined $name;
    confess "Error: Sequence parameter required" unless defined $seq;
    confess "Error: Invalid sequence characters detected" unless is_seq($seq);
    
    my $print_comment = defined $comment ? ' ' . $comment : '';
    say '>', $name, $print_comment;
    print split_string($seq);
}

# Print FASTQ format
sub fu_printfastq {
    my ($name, $comment, $seq, $qual) = @_;
    confess "Error: Name parameter required" unless defined $name;
    confess "Error: Sequence parameter required" unless defined $seq;
    confess "Error: Quality string required" unless defined $qual;
    confess "Error: Invalid sequence characters detected" unless is_seq($seq);
    confess "Error: Sequence and quality length mismatch" 
        unless length($seq) == length($qual);
    
    my $print_comment = defined $comment ? ' ' . $comment : '';
    say '@', $name, $print_comment;
    print split_string($seq), "+\n", split_string($qual);
}

# Split string into lines
sub split_string {
    my $input_string = $_[0];
    return unless defined $input_string;
    
    my $formatted = '';
    my $line_width = $fu_linesize;
    
    return $input_string . "\n" unless $line_width;
    
    for (my $i = 0; $i < length($input_string); $i += $line_width) {
        my $frag = substr($input_string, $i, $line_width);
        $formatted .= $frag . "\n";
    }
    return $formatted;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proch::Seqfu - SeqFu utilities

=head1 VERSION

version 1.7.0

=head1 SYNOPSIS

    use Proch::Seqfu;
    
    # Check if sequence is valid
    my $is_valid = is_seq('ACGTACGT');    # returns 1
    
    # Get reverse complement
    my $rc = rc('ACGTACGT');              # returns 'ACGTACGT'
    
    # Print sequences in FASTA format
    fu_printfasta('seq1', 'sample sequence', 'ACGTACGT');
    
    # Print sequences in FASTQ format
    fu_printfastq('seq1', 'sample sequence', 'ACGTACGT', 'FFFFFFFF');

=head1 DESCRIPTION

This module provides utilities for manipulating and formatting DNA/RNA sequences, with support for FASTA and FASTQ formats. It also includes functionality to interact with the SeqFu command-line tool.

=head1 FUNCTIONS

=head2 seqfu_version

    my $version = seqfu_version();

Returns the version of the installed SeqFu command-line tool. Returns a version string if SeqFu is installed and properly configured, -2 if there was an error executing the command, or a negative string for other errors.

=head2 has_seqfu

    my $has_seqfu = has_seqfu();

Checks if SeqFu is available in the system. Returns:
    1     if SeqFu is available
    0     if SeqFu is not available
    undef if the check failed

=head2 is_seq

    my $valid = is_seq($sequence);

Validates if a string contains only valid nucleotide characters (ACGTRYSWKMBDHVNU, case insensitive).
Returns true if the sequence is valid, false otherwise.

=head2 rc

    my $reverse_complement = rc($sequence);

Generates the reverse complement of a DNA/RNA sequence. Handles both DNA and RNA (U/T) automatically.
Returns undefined if the input sequence contains invalid characters.

=head2 verbose

    verbose("Processing sequence...");

Prints a message to STDERR if verbose mode is enabled ($fu_verbose is true).
Messages are prefixed with " - ".

=head2 fu_printfasta

    fu_printfasta($name, $comment, $sequence);

Prints a sequence in FASTA format. The comment parameter is optional.
Dies with an error message if:
    - name is undefined
    - sequence is undefined
    - sequence contains invalid characters

=head2 fu_printfastq

    fu_printfastq($name, $comment, $sequence, $quality);

Prints a sequence in FASTQ format. The comment parameter is optional.
Dies with an error message if:
    - name is undefined
    - sequence is undefined
    - quality string is undefined
    - sequence contains invalid characters
    - sequence and quality lengths don't match

=head1 CONFIGURATION VARIABLES

=over 4

=item $fu_linesize

Controls the line width for sequence output. If set to 0 (default), sequences are printed without line breaks.

=item $fu_verbose

Controls verbose output. Set to 1 to enable verbose messages, 0 to disable.

=back

=head2 split_string

    my $formatted = split_string($input_string);

Splits a string into lines of length $fu_linesize. Returns the formatted string with line breaks.

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2027 by Quadram Institute Bioscience.

This is free software, licensed under:

  The MIT (X11) License

=cut

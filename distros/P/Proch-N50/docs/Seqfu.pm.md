# SYNOPSIS

    use Proch::Seqfu;
    
    # Check if sequence is valid
    my $is_valid = is_seq('ACGTACGT');    # returns 1
    
    # Get reverse complement
    my $rc = rc('ACGTACGT');              # returns 'ACGTACGT'
    
    # Print sequences in FASTA format
    fu_printfasta('seq1', 'sample sequence', 'ACGTACGT');
    
    # Print sequences in FASTQ format
    fu_printfastq('seq1', 'sample sequence', 'ACGTACGT', 'FFFFFFFF');

# DESCRIPTION

This module provides utilities for manipulating and formatting DNA/RNA sequences, with support for FASTA and FASTQ formats. It also includes functionality to interact with the SeqFu command-line tool.

# FUNCTIONS

## seqfu\_version

    my $version = seqfu_version();

Returns the version of the installed SeqFu command-line tool. Returns a version string if SeqFu is installed and properly configured, -2 if there was an error executing the command, or a negative string for other errors.

## has\_seqfu

    my $has_seqfu = has_seqfu();

Checks if SeqFu is available in the system. Returns:
    1     if SeqFu is available
    0     if SeqFu is not available
    undef if the check failed

## is\_seq

    my $valid = is_seq($sequence);

Validates if a string contains only valid nucleotide characters (ACGTRYSWKMBDHVNU, case insensitive).
Returns true if the sequence is valid, false otherwise.

## rc

    my $reverse_complement = rc($sequence);

Generates the reverse complement of a DNA/RNA sequence. Handles both DNA and RNA (U/T) automatically.
Returns undefined if the input sequence contains invalid characters.

## verbose

    verbose("Processing sequence...");

Prints a message to STDERR if verbose mode is enabled ($fu\_verbose is true).
Messages are prefixed with " - ".

## fu\_printfasta

    fu_printfasta($name, $comment, $sequence);

Prints a sequence in FASTA format. The comment parameter is optional.
Dies with an error message if:
    - name is undefined
    - sequence is undefined
    - sequence contains invalid characters

## fu\_printfastq

    fu_printfastq($name, $comment, $sequence, $quality);

Prints a sequence in FASTQ format. The comment parameter is optional.
Dies with an error message if:
    - name is undefined
    - sequence is undefined
    - quality string is undefined
    - sequence contains invalid characters
    - sequence and quality lengths don't match

# CONFIGURATION VARIABLES

- $fu\_linesize

    Controls the line width for sequence output. If set to 0 (default), sequences are printed without line breaks.

- $fu\_verbose

    Controls verbose output. Set to 1 to enable verbose messages, 0 to disable.

## split\_string

    my $formatted = split_string($input_string);

Splits a string into lines of length $fu\_linesize. Returns the formatted string with line breaks.

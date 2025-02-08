# NAME

fu-len - Filter and manipulate FASTA/FASTQ files based on sequence length

# SYNOPSIS

    fu-len [options] FILE1 [FILE2 ...]

# DESCRIPTION

fu-len is a versatile tool for filtering sequences from FASTA/FASTQ files based on
their length. It provides additional functionality for sequence reformatting and
name manipulation. The tool can process both FASTA and FASTQ files, including
gzipped files, and can handle input from standard input using '-' as the filename.

# OPTIONS

## Input/Output Control

- **-m**, **--min** _INT_

    Minimum length to keep a sequence. Sequences shorter than this will be filtered out.

- **-x**, **--max** _INT_

    Maximum length to keep a sequence. Sequences longer than this will be filtered out.

- **-f**, **--fasta**

    Force output in FASTA format, regardless of input format.

- **-w**, **--fasta-width** _INT_

    Wrap FASTA sequence lines to the specified width. If not specified, sequences will
    be written as single lines.

## Sequence Naming

- **-n**, **--namescheme** _STR_

    Choose how sequence names should be generated. Available schemes:

    - **raw** - Use original sequence names (default)
    - **num** - Number sequences sequentially (see **--prefix**)
    - **file** - Use input filename as prefix followed by sequence number

- **-p**, **--prefix** _STR_

    Prefix to use for sequence names when using the 'num' name scheme.

- **-s**, **--separator** _STR_

    Separator to use between prefix and number (default: '.').

## Sequence Annotation

- **-l**, **--len**

    Add sequence length as a comment to each sequence header.

- **-c**, **--strip-comment**

    Remove existing sequence comments.

## Other Options

- **-v**, **--verbose**

    Print verbose information to STDERR.

- **--version**

    Print version information and exit.

# EXAMPLES

Filter sequences by length:

    # Keep sequences between 100 and 1000 bp
    fu-len -m 100 -x 1000 input.fa > filtered.fa

Convert FASTQ to wrapped FASTA:

    # Convert to FASTA and wrap to 60 characters per line
    fu-len -f -w 60 input.fastq > output.fa

Number sequences with custom prefix:

    # Add sequential numbers and length information
    fu-len -n num -p 'seq' -l input.fa > numbered.fa

Process multiple files:

    # Filter all sequences and force FASTA output
    fu-len -m 500 -f file1.fq file2.fa > combined.fa

# NOTES

When processing multiple files, be aware that:

- Duplicate sequence names can cause errors
- Mixing FASTA and FASTQ files without **--fasta** may cause formatting issues
- Memory usage increases when checking for duplicate names

# MODERN ALTERNATIVE

This suite of tools has been superseded by **SeqFu**, a compiled program providing
faster and safer tools for sequence analysis. This suite is maintained for the
higher portability of Perl scripts under certain circumstances.

SeqFu is available at [https://github.com/telatin/seqfu2](https://github.com/telatin/seqfu2), and can be installed
with BioConda `conda install -c bioconda seqfu`

# CITING

Telatin A, Fariselli P, Birolo G.
_SeqFu: A Suite of Utilities for the Robust and Reproducible Manipulation of Sequence Files_.
Bioengineering 2021, 8, 59. [https://doi.org/10.3390/bioengineering8050059](https://doi.org/10.3390/bioengineering8050059)

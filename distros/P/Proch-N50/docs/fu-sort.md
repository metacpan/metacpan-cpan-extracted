# NAME

fu-sort - Sort sequences by size with flexible output formatting

# SYNOPSIS

    fu-sort [options] filename [...]

# DESCRIPTION

fu-sort reads FASTA/FASTQ files and sorts sequences by length in either ascending
or descending order. It provides various output formatting options and can handle
both FASTA and FASTQ formats.

# OPTIONS

## Sorting Options

- **--asc**

    Sort sequences in ascending order (default: descending)

## Output Formatting

- **--w**, **--line-width** _N_

    Width for FASTA sequence lines (0 for unlimited)

- **--sc**, **--strip-comments**

    Remove sequence comments

- **--fasta**

    Force FASTA output format

- **--fastq**

    Force FASTQ output format

- **--rc**

    Output reverse complement sequences

- **--q**, **--qual** _n.n_

    Default quality score for FASTQ output

- **--u**, **--upper**

    Convert sequences to uppercase

## Sequence Annotation

- **--al**, **--add-length**

    Add sequence length to comments

## Other Options

- **--quiet**

    Suppress progress messages

- **--debug**

    Enable debug output

- **--version**

    Display version information

- **--help**

    Show this help message

# EXAMPLES

Sort sequences by length (longest first):

    fu-sort input.fa > sorted.fa

Sort sequences by length (shortest first):

    fu-sort --asc input.fa > sorted.fa

Sort and add length information:

    fu-sort --add-length input.fa > sorted_with_length.fa

Convert to FASTA with wrapped sequences:

    fu-sort --fasta --line-width 60 input.fastq > wrapped.fa

# MODERN ALTERNATIVE

This suite of tools has been superseded by **SeqFu**, a compiled
program providing faster and safer tools for sequence analysis.
This suite is maintained for the higher portability of Perl scripts
under certain circumstances.

SeqFu is available at [https://github.com/telatin/seqfu2](https://github.com/telatin/seqfu2), and
can be installed with BioConda `conda install -c bioconda seqfu`

# CITING

Telatin A, Fariselli P, Birolo G.
_SeqFu: A Suite of Utilities for the Robust and Reproducible Manipulation of Sequence Files_.
Bioengineering 2021, 8, 59. [https://doi.org/10.3390/bioengineering8050059](https://doi.org/10.3390/bioengineering8050059)

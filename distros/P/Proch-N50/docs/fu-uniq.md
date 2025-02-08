# NAME

fu-uniq - Dereplicate sequences and generate abundance information

# SYNOPSIS

    fu-uniq [options] input.fa > uniq.fa

# DESCRIPTION

fu-uniq is a tool for dereplicating DNA sequences and generating abundance
information. It identifies unique sequences and can track their abundance
using USEARCH-style labels. The tool supports both exact sequence matching
and customizable output formats.

Key features:
\- Dereplicates sequences while maintaining abundance information
\- Supports USEARCH-style size annotations
\- Flexible sequence naming options
\- Handles both FASTA and FASTQ inputs
\- Processes gzipped files automatically

# OPTIONS

## Sequence Processing

- **-k**, **--keepname**

    Use the name of the first occurrence of each unique sequence as the cluster name.
    This is useful for maintaining meaningful identifiers. Default: ON

- **-m**, **--min-size** _N_

    Only output sequences that appear at least N times. This helps filter out
    rare sequences or potential sequencing errors. Default: 0 (no filtering)

- **--size-as-comment**

    Add size information as a comment rather than part of the sequence name.
    This affects the format of the output headers. Default: OFF

    Example with option OFF:
        >seq1;size=10;
    Example with option ON:
        >seq1    size=10;

## Output Formatting

- **-p**, **--prefix** _STR_

    Prefix for sequence names when not using --keepname. Default: 'seq'

- **-s**, **--separator** _STR_

    Character(s) to separate prefix from sequence number. Default: '.'

- **-w**, **--line-width** _N_

    Width for wrapping FASTA sequence lines. Use 0 for single-line sequences.
    Default: 80

# EXAMPLES

Basic deduplication:

    # Find unique sequences and add abundance information
    fu-uniq input.fa > uniq.fa

Keep only abundant sequences:

    # Keep sequences that appear at least 10 times
    fu-uniq -m 10 input.fa > abundant.fa

Custom sequence naming:

    # Use custom prefix and separator
    fu-uniq -p 'cluster' -s '_' input.fa > clusters.fa

Process multiple files:

    # Combine and deduplicate multiple files
    fu-uniq file1.fa file2.fa > combined_uniq.fa

Add size as comment:

    # Place size information in sequence comment
    fu-uniq --size-as-comment input.fa > commented.fa

# NOTES

- Memory usage scales with the number of unique sequences
- Sequence comparison is case-insensitive
- Size annotations in input files (;size=N;) are respected and combined

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

# NAME

fu-grep - Extract sequences using patterns from FASTA/FASTQ files

# SYNOPSIS

    fu-grep [options] Pattern InputFile.fa [...]

# DESCRIPTION

fu-grep is a versatile tool for searching and extracting sequences from FASTA/FASTQ files
based on various criteria. It can search for patterns in:

- DNA sequences (including reverse complement)
- Sequence names
- Sequence comments

The tool supports both stranded and unstranded searches, and can provide detailed
annotations about the matches found.

# OPTIONS

- **-a**, **--annotate**

    Add comments to the sequence when match is found. The annotation includes:

    - Total number of matches
    - Number of forward matches
    - Number of reverse complement matches (unless --stranded is used)
    - Source filename (when processing multiple files)

- **-n**, **--name**

    Search pattern in sequence name instead of the sequence itself

- **-c**, **--comments**

    Search pattern in sequence comments instead of the sequence itself

- **-s**, **--stranded**

    Do not search for reverse complemented oligo

- **-f**, **--fasta**

    Force output in FASTA format, even for FASTQ input

- **--cs**, **--comment-separator** _STR_

    Specify custom comment separator (default: tab)

- **-v**, **--verbose**

    Print verbose output

- **-d**, **--debug**

    Print debug information

- **--version**

    Print version information and exit

# EXAMPLES

Search for a specific DNA pattern:

    fu-grep AAGCTT input.fa > matched.fa

Search in multiple files with annotation:

    fu-grep -a AAGCTT sample1.fa sample2.fa > matches.fa

Search in sequence names:

    fu-grep -n "gene" sequences.fa > named.fa

Process FASTQ file but output in FASTA format:

    fu-grep -f AAGCTT input.fastq > output.fa

# NOTES

The tool will automatically search for both forward and reverse complement sequences
unless the --stranded option is used.

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

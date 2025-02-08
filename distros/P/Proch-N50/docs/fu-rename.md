# SYNOPSIS

    fu-rename [options] InputFile.fa [InputFile2.fa ...]

    # Rename sequences in a single file
    fu-rename input.fa > renamed.fa

    # Process multiple files with custom prefix
    fu-rename -p 'sample' file1.fa file2.fa > renamed.fa

    # Reset counter for each file
    fu-rename -r file1.fa file2.fa > renamed.fa

# DESCRIPTION

A tool for systematic renaming of sequences in FASTA/FASTQ files. It provides
flexible options for naming patterns and maintains sequence quality when
processing FASTQ files. The program can handle multiple input files and
supports reading from standard input.

# PARAMETERS

- `-p`, `--prefix` STRING

    New sequence name (accepts placeholders). Default value is "{b}". 
    Available placeholders:
        {b} = File basename without extensions
        {B} = File basename with extension

- `-s`, `--separator` STRING

    Separator between prefix and sequence number. Default is "."

- `-r`, `--reset`

    Reset counter at each file. By default, the counter continues across all files.

- `-f`, `--fasta`

    Force FASTA output even for FASTQ input files.

- `-n`, `--nocomments`

    Suppress comments in sequence headers.

- `-v`, `--verbose`

    Enable verbose output for debugging.

- `--version`

    Display version information.

# FEATURES

- Preserves quality scores when processing FASTQ files
- Supports multiple input files
- Flexible naming patterns with placeholders
- Optional counter reset for each input file
- Maintains compatibility with both FASTA and FASTQ formats

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

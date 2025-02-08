# NAME

fu-cat - concatenate FASTA or FASTQ files

# SYNOPSIS

    fu-cat [options] [FILE1 FILE2 FILE3...]

# DESCRIPTION

This program parses a list of FASTA/FASTQ and will concatenate them
ensuring consistent output. Will rename duplicate sequence names.
Will try to autodetect the format of all files before executing and
decide accordingly the output format (FASTA if at least one of the
files is FASTA, otherwise FASTQ). If reading from STDIN the first
sequence is in FASTQ format, will skip all the sequences without a
quality string.

If no files are provided the program will try reading from STDIN,
otherwise add a '-' to the list of files to also read from STDIN.

# PARAMETERS

- _-s_, _--separator_

    When a second sequence with a name that was already printed is found,
    the program will append a progressive number, separated by this string.
    Use \`fu-rename\` if you need more options.
    \[default: "."\]

- _-f_, _--fasta_

    Force FASTA output

- _-q_, _--fastq_

    Force FASTQ output. Will **not** print any sequence without quality
    (they will be skipped)

- _-d_, _--dereplicate_

    Print each sequence only only once

- _-5_, _--rename-md5_

    (use with -d) rename each sequence name with the MD5sum of the sequence.

- _-l_, _--minlen_ INT

    Do not print sequences shorter (exclusive) than INT

- _-m_, _--maxlen_ INT

    Do not print sequences longer (exclusive) than INT

- _-u_, _--uppercase_

    Will print the whole sequence in uppercase

- _-w_, _--width_ INT

    Size of the FASTA lines. Specifing 0 will print the whole sequence in the same line (default: 0)

- _--verbose_

    Print more details

- _--help_

    Display this help page

- _--version_

    Print version and exit

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

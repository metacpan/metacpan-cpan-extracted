# NAME

fu-count - A FASTA/FASTQ sequence counter

# VERSION

version 1.5.0

# SYNOPSIS

    fu-count [options] [FILE1 FILE2 FILE3...]

# DESCRIPTION

This program parses a list of FASTA/FASTQ files printing the number of sequences
found in each file. Reads both uncompressed and GZipped files.
Default output is the filename, tab, sequence count. Can be changed with options.

The table "key" is the absolute path of each input file, but the printed name can be
changed with options.

# NAME

fu-count - A FASTA/FASTQ sequence counter

# PARAMETERS

## FILE NAME

- _-a, --abspath_

    Print the absolute path of the filename (the absolute path is always the table key,
    but if relative paths are supplied, they will be printed).

- _-b, --basename_

    Print the filename without the path.

- _-d, --thousandsep_

    Print reads number with a "," used as thousand separator

## OUTPUT FORMAT

Default output format is the filename and reads counts, tab separated. Options formatting
either filename (`-a`, `-b`) and reads counts (`-d`) will still work.

- _-t, --tsv_ and _-c, --csv_

    Print a tabular output either tab separated (with `-t`) or comma separated (with `-c`).

- _-j, --json_

    Print full output in JSON format.

- _-p,  --pretty_

    Same as JSON but in "pretty" format.

- _-x, --screen_

    This feature requires [Term::ASCIITable](https://metacpan.org/pod/Term%3A%3AASCIITable).
    Print an ASCII-art table like:

        .---------------------------------------------------.
        | # | Name                     | Seqs | Gz | Parser |
        +---+--------------------------+------+----+--------+
        | 1 | data/comments.fasta      |    3 |  0 | FASTX  |
        | 2 | data/comments.fastq      |    3 |  0 | FASTQ  |
        | 3 | data/compressed.fasta.gz |    3 |  1 | FASTX  |
        | 4 | data/compressed.fastq.gz |    3 |  1 | FASTQ  |
        '---+--------------------------+------+----+--------'

## SORTING

- _-s, --sortby_

    Sort by field: 'order' (default, that is the order of the input files as supplied by the user),
    'count' (number of sequences), 'name' (filename).
    By default will be descending for numeric fields, ascending for 'path'.
    See `-r, --reverse`.

- _-r, --reverse_

    Reverse the sorting order.

## OTHER

- _-f, --fastx_

    Force FASTX reader also for files ending by .fastq or .fq (by default would use getFastqRead() )

- _-v, --verbose_

    Increase verbosity

- _-h, --help_

    Display this help page

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

# AUTHOR

Andrea Telatin <andrea@telatin.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Andrea Telatin.

This is free software, licensed under:

    The MIT (X11) License

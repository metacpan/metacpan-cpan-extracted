# NAME

fu-extract - Get sequences by name (also using lists)

# VERSION

version 1.5.0

# PARAMETERS

- `-p, --pattern` PATTERN

    Print only sequences containing the given pattern in their name

- `-l, --list` FILE

    Print only sequences in the given list file (full name must match)

- `-c, --column` COLUMN

    In the list file, consider the name as the column COLUMN (default: 1)

- `-h, --header` CHAR

    Ignore lines starting with CHAR in the list (default: "#")

- `-s, --separator` CHAR

    Split the lines in the list file by CHAR (default: "\\\\t")

- `-i, --case-insensitive`

    Ignore case in the name	(works both with `-p` and `-l`)

- `-m, --minlen` MINLEN

    Print only sequences with a length greater than MINLEN

- `-x, --maxlen` MAXLEN

    Print only sequences with a length less than MAXLEN

- `-v, --verbose`

    Print more information

# EXAMPLES

Search by sequence name:

    fu-extract -p 'BamHI' test.fa

Use a list to extract sequences:

    fu-extract -l list.txt test.Fasta

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

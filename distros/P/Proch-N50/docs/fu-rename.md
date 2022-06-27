# NAME

fu-rename - rename sequences

# VERSION

version 1.4.8

# SYNOPSIS

    fu-cat [options] [FILE1 FILE2 FILE3...]

# PARAMETERS

- `-p`, `--prefix` STRING

    New sequence name (accept placehodlers), default is "{b}"

- `-s`, `--separator` STRING

    Separator between prefix and sequence number

- `-r`, `--reset`

    Reset counter at each file

# EXAMPLE

    fu-rename -p '{b}' test.fa test2.fa > renamed.fa

Placeholders: `{b}` = File basename without extensions, and 
`{B}` = File basename with extension

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

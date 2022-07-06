# NAME

fu-grep - Extract sequences using patterns

# VERSION

version 1.5.0

# USAGE

    fu-grep [options] Pattern InputFile.fa [...]

## PARAMETERS

- `-a`, `--annotate`

    Add comments to the sequence when match is found

- `n`, `--name`

    Search pattern in sequence name (default: sequence)

- `c`, `--comments`

    Search pattern in sequence comments (default: sequence)

- `s`, `--stranded`

    Do not search reverse complemented oligo

- `f`, `--fasta`

    Force output in FASTA format

# EXAMPLES

    fu-grep DNASTRING test.fa test2.fa > matched.fa

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

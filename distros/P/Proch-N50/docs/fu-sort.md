# NAME

fu-sort - Sort sequences by size

# VERSION

version 1.4.8

# EXAMPLES

    fu-sort seq.fa > sorted.fa

# PARAMETERS

- `--asc`             

    Print in ascending order (defaul: descending)

- `--al|add-length`    

    Add length=LEN to the comment

- `--help`             

    This help

- `--version`          

    Print version and exit

- `--quiet`            

    No screen output (default OFF)

- `--debug`            

    Debug mode (default OFF)

## Common options

- `--w|line-width` \[N\] 

    FASTA line size (0 for unlimited)

- `--sc|strip-comments` 

    Strip comments

- `--fasta`            

    Force FASTA output

- `--fastq`            

    Force FASTQ output

- `--rc`               

    Print reverse complementary

- `--q|qual` \[n.n\]     

    Default quality for FASTQ files

- `--u|upper`          

    Convert sequence to uppercase

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

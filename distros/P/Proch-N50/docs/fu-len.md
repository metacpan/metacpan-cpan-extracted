# NAME

fu-len - A demo implementation to filter fastx files by length

# VERSION

version 1.5.0

# USAGE

    fqlen [options] FILE1 FILE2 ... FILEn

## PARAMETERS

- `-m`, `--min` INT                   

    Minimum length to print a sequence

- `-x`, `--max` INT                   

    Maximum length to print a sequence

- `-l`, `--len`                       

    Add read length as comment

- `-f`, `--fasta`                     

    Force FASTA output (default: as INPUT)

- `-w`, `--fasta-width` INT           

    Paginate FASTA sequences (default: no)

- `-n`, `--namescheme`                

    Sequence name scheme: **"file"** (Use file basename as prefix),
    **"num"** (Numbered sequence (see also -p)) and
    **"raw"** (Do not change sequence name, default)

- `-p`, `--prefix` STR

    Use as sequence name prefix this string

- `-c`, `--strip-comment`

    Remove sequence comment (default: no)

# LIMITATIONS

Note that usage with multiple files can raise errors (eg. duplicate sequence name). 
Also, wrong formatting if mixing fasta and fastq files without 
specifying --fasta.

We recommend considering SeqFu to overcome these limitations: [https://github.com/telatin/seqfu2](https://github.com/telatin/seqfu2).

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

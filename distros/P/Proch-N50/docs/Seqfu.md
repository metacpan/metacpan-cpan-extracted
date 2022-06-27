# NAME

Proch::Seqfu - Helper module to support Seqfu tools

# VERSION

version 1.4.8

# Proch::Seqfu

a legacy module for Seqfu utilities

## fu\_printfasta(name, comment, seq)

This function prints a sequence in fasta format

## fu\_printfastq(name, comment, seq, qual)

This function prints a sequence in FASTQ format

## verbose(msg)

Print a text if $fu\_verbose is set to 1

## rc(dna)

Return the reverse complement of a string \[degenerate base not supported\]

## is\_seq(name, comment, seq)

Check if a string is a DNA sequence, including degenerate chars.

## split\_string(dna)

Add newlines using $Proch::SeqFu::fu\_linesize as line width

# AUTHOR

Andrea Telatin <andrea@telatin.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Andrea Telatin.

This is free software, licensed under:

    The MIT (X11) License

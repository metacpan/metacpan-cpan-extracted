## NAME

**qzoom.pl** - a helper utility to extract data from Qiime2 artifact

## AUTHOR

Andrea Telatin <andrea@telatin.com>

## SYNOPSIS

qzoom.pl \[options\] &lt;artifact1.qza/v> \[&lt;artifact2.qza ...\]

## OPTIONS

### Main Actions

> **-i, --info**
>
> Print artifact citation to STDOUT or to file, is a filepath is provided.
> Enabled by default if no `--cite` or `--extract` are defined.
>
> **-c, --cite**
>
> Print artifact citation to STDOUT or to file. Specify -b FILE to save it.
>
> **-x, --extract**
>
> Print the list of files in the 'data' directory.
> If a OUTDIR is provided, extract the content of the 'data' directory (i.e. the actual output of the artifact).
> Will create the directory if not found. Will overwrite files in the directory.
>
> **-d, --data**
>
> List all the files contained in the ./data directory of the artifacts

### Other parameters

> **-o, --outdir** _OUTDIR_
>
> Directory where to extract files (default: ./), to use with `-x`, `--extract`.
>
> **-b, --bibtex** _FILE_
>
> Save citations to a file (append), to use with `-c`, `--cite`.
>
> **-r, --rename**
>
> Rename the content of the artifact to {artifactbasename}.{ext}.
> Used with `-x` will extract `dna-sequences.fasta` from `dada2repseq.qza` as
> `dada2repseq.fasta`. Only works with single file artifacts.
>
> **--verbose**
>
> Print verbose output.

## BUGS

Please report them to <andrea@telatin.com>

## COPYRIGHT

Copyright (C) 2019 Andrea Telatin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/>.

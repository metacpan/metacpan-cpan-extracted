#!/bin/bash


echo "

# Proch::N50

[![Ubuntu](https://github.com/telatin/proch-n50/actions/workflows/ubuntu.yaml/badge.svg)](https://github.com/telatin/proch-n50/actions/workflows/ubuntu.yaml)
[![Windows](https://github.com/telatin/proch-n50/actions/workflows/windows.yml/badge.svg)](https://github.com/telatin/proch-n50/actions/workflows/windows.yml)

a small module to calculate N50 (total size, and total number of sequences) for a FASTA or FASTQ file. It's easy to install, with minimal dependencies.

 * Distribution page in **[MetaCPAN](https://metacpan.org/pod/Proch::N50)**

## Documentation pages
" > README.md


dir="build-release"
out="docs"
mkdir -p "$out"
dzil build --in "$dir"

# prevent shell glob
echo "_binaries"
echo "### Binaries " >> README.md
for i in $(ls -r "$dir"/bin/*); 
do
 if [[ ! -e "$i" ]]; then
   exit
 fi
 
 b=$(basename $i .pl)
 echo $b
 pod2markdown < $i > "$out"/${b}.md
 echo " * [$b](docs/$b.md)" >> README.md
done

echo "### Modules " >> README.md
echo "_Modules"
for m in "$dir"/lib/Proch/*.pm; 
do
 if [[ ! -e "$m" ]]; then
   echo "Not found $m"
   continue
 fi
 
 b=$(basename $m .pm)
 echo $b
 pod2markdown < $m > "$out"/${b}.md
 echo " * [Proch::$b](docs/$b.md)" >> README.md
done

rm -rf "$dir"

echo "

# Citing

Telatin A, Fariselli P, Birolo G. 
**SeqFu: A Suite of Utilities for the Robust and Reproducible Manipulation of Sequence Files**.
Bioengineering 2021, 8, 59. [10.3390/bioengineering8050059](https://doi.org/10.3390/bioengineering8050059)

" >> README.md

echo "Last updated: $(date +%Y-%m-%d)" >> README.md
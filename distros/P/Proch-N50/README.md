# Proch::N50 0.90

[![CPAN](https://img.shields.io/badge/CPAN-Proch::N50-1abc9c.svg)](https://metacpan.org/pod/Proch::N50)
[![Kwalitee](https://cpants.cpanauthors.org/release/PROCH/Proch-N50-0.70.svg)](https://cpants.cpanauthors.org/release/PROCH/Proch-N50-0.70)
[![Version](https://img.shields.io/cpan/v/Proch-N50.svg)](https://metacpan.org/pod/Proch::N50)
[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/perl-fastx-reader/README.html)
[![Tests](https://img.shields.io/badge/Tests-Grid-1abc9c.svg)](https://www.cpantesters.org/distro/P/Proch-N50.html)

### A simple Perl module to calculate N50 of a FASTA or FASTQ file

The updated documentation is in the *[Meta::CPAN page](https://metacpan.org/pod/Proch::N50)*.

The module ships the **n50** program to calculate the N50 of FASTA/FASTQ files ([documentation](https://metacpan.org/pod/distribution/Proch-N50/bin/n50)).

### Installation - perl way

Via CPANminus:
```
#If you don't have 'cpanm' already installed:
curl -L http://cpanmin.us | perl - App::cpanminus

cpanm Proch::N50
```

### Conda N50

You can install 'n50' to calculate the N50 of a FASTA/FASTQ file with Miniconda, with the command:

```
conda install -y -c bioconda n50
```

## n50 program

See full documentation [in the CPAN page](https://metacpan.org/pod/distribution/Proch-N50/bin/n50).

 - Simple usage with one input file (FASTA or FASTQ):

```bash
n50 file.fasta
```

 - Use the output in bash scripts:
```
MY_N50=$(n50 input.fasta -n)
```

 - Screen friendly table (-x is a shortcut for --format screen), sorted by N50 descending (default):
```
n50.pl -x files/*.fa
```

 - Screen friendly table, sorted by total contig length (--sortby max) ascending (--reverse):

```
n50.pl -x -o max -r files/*.fa
```

 - Tabular (tsv) output is default:

```
n50 -o max -r files/*.fa

```

 - To print data with your custom output format:

```
n50 data/*.fa -f custom -t '{path}{tab}N50={N50};Sum={size}{new}'

```

### Output formats

 - tsv (tab separated values)

```
#path seqs    size    N50     min     max
test2.fa      8        825    189     4       256
reads.fa      5        247    100     6       102
small.fa      6       130     65      4       65
```

 - csv (comma separated values), same as `--format tsv` and `--separator`,:

```
#path,seqs,size,N50,min,max
test.fa,8,825,189,4,256
reads.fa,5,247,100,6,102
small_test.fa,6,130,65,4,65
```

 - screen friendly, `-x` as shortcut for `--format screen`:
```
    .-----------------------------------------------------------.
    | File               | Seqs  | Total bp | N50  | min | max  |
    +--------------------+-------+----------+------+-----+------+
    | test_fasta_grep.fa |     1 |       80 |   80 |  80 |   80 |
    | small_test.fa      |     6 |      130 |   65 |   4 |   65 |
    | rdp_16s_v16.fa     | 13212 | 19098167 | 1467 | 320 | 2210 |
    '--------------------+-------+----------+------+-----+------'
```

 - json (JSON), use `-j` as shortcut for `--format json`:

```
    {
      "small_test.fa" : {
         "max"  : 65,
         "N50"  : 65,
         "seqs" : 6,
         "size" : 130,
         "min"  : 4
      },
      "rdp_16s_v16.fa" : {
         "seqs" : 13212,
         "N50"  : 1467,
         "max"  : 2210,
         "min"  : 320,
         "size" : 19098167
      }
    }
```


## Proch::N50 - short synopsis of the module

```perl
use Proch::N50 qw(getStats getN50);
my $filepath = '/path/to/assembly.fasta';

# Get N50 only: getN50(file) will return an integer
print "N50 only:\t", getN50($filepath), "\n";

# Full stats
my $seq_stats = getStats($filepath);
print Data::Dumper->Dump( [ $seq_stats ], [ qw(*FASTA_stats) ] );
# Will print:
# %FASTA_stats = (
#               'N50' => 65,
#               'dirname' => 'data',
#               'size' => 130,
#               'seqs' => 6,
#               'filename' => 'small_test.fa',
#               'status' => 1
#             );

# Get also a JSON object
my $seq_stats_with_JSON = getStats($filepath, 'JSON');
print $seq_stats_with_JSON->{json}, "\n";
# Will print:
# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
```

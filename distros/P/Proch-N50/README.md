# Proch::N50
[![CPAN](https://img.shields.io/badge/CPAN-Proch::N50-1abc9c.svg)](https://metacpan.org/pod/Proch::N50)
[![Kwalitee](https://cpants.cpanauthors.org/release/PROCH/Proch-N50-0.03.svg)](https://cpants.cpanauthors.org/release/PROCH/Proch-N50-0.03)
[![Version](https://img.shields.io/cpan/v/Proch-N50.svg)](https://metacpan.org/pod/Proch::N50)
[![Tests](https://img.shields.io/badge/Tests-Grid-1abc9c.svg)](https://www.cpantesters.org/distro/P/Proch-N50.html)
### A simple Perl module to calculate N50 of a FASTA or FASTQ file

For updated documentation, please visit *[Meta::CPAN](https://metacpan.org/pod/Proch::N50)*.

### Short synopsis

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

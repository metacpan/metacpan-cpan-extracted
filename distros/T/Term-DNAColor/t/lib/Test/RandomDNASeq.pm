use strict;
use warnings;
use utf8;

package Test::RandomDNASeq;
# ABSTRACT: Generate random DNA or RNA sequences

use base 'Exporter::Simple';
use String::Random qw(random_regex);
use List::AllUtils qw(max);
use Algorithm::Numerical::Shuffle qw(shuffle);

# All possible nucleotides
my @nucleotides = qw(A T C G N);

# Character class matching any one nucleotide
my $nucl_class = "[" . join("", @nucleotides) . "]";

# this produces a random DNA sequence that is guaranteed to have at
# least one instance of each letter in it. Optional arg specifies the
# length of the sequence.
sub random_dna : Exported {
    my $length = max(scalar(@nucleotides), shift || 20) - scalar(@nucleotides);
    my $regex = $nucl_class . "{$length}";
    my $seq = random_regex($regex);
    # Randomly splice in one of each letter to guarantee that at least
    # one of each letter is in there.
    substr($seq, rand(length($seq)), 0, join("", shuffle(@nucleotides)));
    return $seq;
}

sub dna2rna : Exported {
    local $_ = $_[0];
    s/T/U/g;
    s/t/u/g;
    return $_;
}

# Same as random_dna except that T is replaced by U
sub random_rna : Exported {
    return dna2rna(random_dna(@_));
}

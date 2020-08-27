#!/usr/bin/perl
#
# extract a rough dictionary of reliable word translations from phrase tables
#

use Getopt::Std;
our ($opt_s,$opt_t);

getopts('s:t:');

my $minProb = 0.1;  # minimal score for p(e|f) and p(f|e)
my $minFreq = 2;    # minimal frequency (both sides)

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");


while (<>){
    my @parts = split(/\s*\|\|\|\s*/);

    # next if ($parts[0] eq $parts[1]);  # skip identicals (??)

    unless ($opt_s=~/^(zh|ja)/){
        next if ($parts[0]=~/\s/);   # only one-word translations!
    }
    unless ($opt_t=~/^(zh|ja)/){
        next if ($parts[1]=~/\s/);
    }

    next if ($parts[0]=~/\P{IsAlpha}/); # skip words containing non-letters
    next if ($parts[1]=~/\P{IsAlpha}/); # skip words containing non-letters

#    next if ($parts[0]!~/\P{P}/); # skip punctuations
#    next if ($parts[1]!~/\P{P}/); # skip punctuations

    unless ($opt_s=~/^(zh|ja)/){
        next if (length($parts[0]) < 3); # skip 1 and 2-letter words
    }
    unless ($opt_t=~/^(zh|ja)/){
        next if (length($parts[1]) < 3); # skip 1 and 2-letter words
    }

    my @scores = split(/\s/,$parts[2]);
    next if (@scores[0] < $minProb);
    next if (@scores[2] < $minProb);

    my @freqs = split(/\s/,$parts[4]);
    next if (@freqs[0] < $minFreq);
    next if (@freqs[1] < $minFreq);

    print $parts[0],' ',$parts[1],"\n";
}

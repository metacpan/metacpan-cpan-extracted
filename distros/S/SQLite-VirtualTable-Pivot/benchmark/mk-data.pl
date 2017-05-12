#!/usr/bin/perl

my $rows = @ARGV[0] or die "usage: $0 <rows>\n";

my @fields = qw/alpha beta gamma word_1 word_2 word_3/;
my @word_vals = map "wordval_$_", (1..10);
my $gamma = 9990;

srand(100);
for my $id (1..$rows) {
    for my $f (qw/alpha beta/) {
        my $value = int rand 1000;
        print "$id,$f,$value\n";
    }
    print "$id,gamma,$gamma\n";
    $gamma++;
    for my $g (qw/word_1 word_2 word_3/) {
        my $value = @word_vals[int rand $#word_vals];
        print "$id,$g,$value\n";
    }
}


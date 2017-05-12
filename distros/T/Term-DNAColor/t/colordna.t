#!perl
use Test::More;
use Term::ANSIColor 2.01 qw(colorstrip color);
use Term::DNAColor;

use lib 't/lib';
use Test::RandomDNASeq;

diag "You can manually verify the correctness of the following:";
for (1..3) {
    my $random_seq = random_dna();
    diag "Sequence $_:         $random_seq";
    my $colored_seq = colordna($random_seq);
    diag "Colored Sequence $_: $colored_seq";

    ok($colored_seq, "colordna returned something");
    is(colorstrip($colored_seq), $random_seq, "colordna does not change characters, only adds colors between them");

    my $reset_end_regexp = quotemeta(color('reset')) . '$';
    ok($colored_seq =~ m{$reset_end_regexp}, "Colored sequence ends with ANSI reset code");
}

done_testing();

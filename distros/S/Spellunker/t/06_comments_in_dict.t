use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }

use Spellunker;

my $spellunker = Spellunker->new();

my @words = qw(aabbcc bbccaa ccbbaa);

foreach my $w(@words) {
    ok !$spellunker->check_word($w), 'unregistered word';
}

$spellunker->load_dictionary(\*DATA);

foreach my $w(@words) {
    ok $spellunker->check_word($w), 'registered word';
}

foreach my $word_in_comment(qw(
    slkjfdaks
    kdjaskla
    dksals
)) {
    ok !$spellunker->check_word($word_in_comment), 'comments are ignored';
}

done_testing;

__DATA__
# slkjfdaks
aabbcc
# kdjaskla
bbccaa # dksals
ccbbaa

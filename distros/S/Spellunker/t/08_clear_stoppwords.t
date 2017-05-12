use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }

use Spellunker;

my $spellunker = Spellunker->new();

$spellunker->load_dictionary(\*DATA);

ok $spellunker->check_word('aaabbbcccddd');

$spellunker->clear_stopwords();

ok !$spellunker->check_word('aaabbbcccddd');

done_testing;

__DATA__
aaabbbcccddd

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

BEGIN { use_ok('Telugu::Utils') };

my $util = Telugu::Utils->new();
my @ngrams = $util->ngram("౿త్ర్మిఅంబ్ర మా 23ి4౷so ಮುಖ್ಯ_ಪುಟ  meయk  బ్రహ్మం stఅఀringలోక్", 2);


ok ($ngrams[0][1] eq 'త్ర్మి');
ok ($ngrams[0][0] eq '౿');

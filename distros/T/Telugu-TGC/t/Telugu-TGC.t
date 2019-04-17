use strict;
use warnings;
use utf8;
use Test::More tests => 19;

BEGIN { use_ok('Telugu::TGC') };

my $o = Telugu::TGC->new();
my @re = $o->TGC("౿త్ర్మి   అంబ్ర మా 23ి4౷so ಮುಖ್ಯ_ಪುಟ  meయk  బ్రహ్మం stఅఀringలోక్");


ok ($re[0] eq '౿');
ok ($re[1] eq 'త్ర్మి');
ok ($re[2] eq ' ');
ok ($re[3] eq ' ');
ok ($re[4] eq ' ');
ok ($re[5] eq 'అం');
ok ($re[6] eq 'బ్ర');
ok ($re[7] eq ' ');
ok ($re[8] eq 'మా');
ok ($re[9] eq ' ');
ok ($re[10] eq '2');
ok ($re[11] eq '3');
ok ($re[12] eq 'ి');
ok ($re[13] eq '4');
ok ($re[14] eq '౷');
ok ($re[15] eq 's');
ok ($re[16] eq 'o');
ok ($re[17] eq ' ');

done_testing();

#########################

use Test;
BEGIN { plan tests => 1 };

use P2P::pDonkey::Meta_v04 ':all';

my $i = makeFileInfo_v04('t/224.avi');
my $packed_i_1 = packFileInfo_v04($i);
my $packed_i_2 = packFileInfo_v04(unpackFileInfo_v04($packed_i_1, $off=0), $off=0);
ok($packed_i_1 eq $packed_i_2);


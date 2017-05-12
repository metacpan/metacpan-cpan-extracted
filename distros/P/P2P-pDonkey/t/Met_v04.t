#########################

use Test;
BEGIN { plan tests => 2 };

use P2P::pDonkey::Met_v04 ':all';

#########################
my $p = readPartMet_v04('t/24.part.met');
ok($p);
$p = readKnownMet_v04('t/known.v04.met');
ok($p);


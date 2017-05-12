#########################

use Test;
BEGIN { plan tests => 4 };

use P2P::pDonkey::Met ':all';

#########################
my $p = readPartMet('t/23.part.met');
ok($p);
$p = readServerMet('t/server.met');
ok($p);
$p = readPrefMet('t/pref.met');
ok($p);
$p = readKnownMet('t/known.met');
ok($p);


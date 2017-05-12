#!perl

use Test::More;

use Net::RIR_CC;

my ($rc, $rir);

ok($rc = Net::RIR_CC->new, 'constructor ok: ' . $rc);
ok($rc->isa('Net::RIR_CC'), 'isa check ok');

done_testing;


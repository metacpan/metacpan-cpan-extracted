use strict;
use warnings;

use Test::More tests => 3;

use Module::Find;

use lib qw(./t/test-malicious);

setmoduledirs('./t/test');

my @l = useall ModuleFindTest;
ok($#l == 1);
ok($l[0] eq 'ModuleFindTest::SubMod');
ok(ModuleFindTest::SubMod::theRealDeal());

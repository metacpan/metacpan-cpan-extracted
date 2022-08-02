use strict;
use warnings;

use Test::More tests => 8;

use Module::Find;

use lib qw(./t/test);

my @l;

@l = findsubmod LoadFailTest;

ok($#l == 0);
ok($l[0] eq 'LoadFailTest::LoadFailMod');

eval { @l = usesub LoadFailTest };
ok($#l == 0);
ok($l[0] eq 'LoadFailTest::LoadFailMod');
ok($@); # OK if loading failed and returned an error

eval { @l = useall LoadFailTest };
ok($#l == 0);
ok($l[0] eq 'LoadFailTest::LoadFailMod');
ok($@); # OK if loading failed and returned an error

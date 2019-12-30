use strict;
use warnings;

use Test::More tests => 7;

use Module::Find;

use lib qw(./t/test);

my @l;

@l = findsubmod ModuleFindTest;

ok($#l == 0);
ok($l[0] eq 'ModuleFindTest::SubMod');

@l = findallmod ModuleFindTest;

ok($#l == 1);
ok($l[0] eq 'ModuleFindTest::SubMod');
ok($l[1] eq 'ModuleFindTest::SubMod::SubSubMod');

@l = findallmod "ModuleFindTest'SubMod";
is($#l, 0, 'Found one module');
is($l[0], "ModuleFindTest'SubMod::SubSubMod");



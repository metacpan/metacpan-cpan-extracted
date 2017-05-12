use Test::More tests => 18;

use Module::Find;

# First, with @INC only

ok($#Module::Find::ModuleDirs == -1);

@l = findsubmod ModuleFindTest;
ok($#l == -1);

@l = findallmod ModuleFindTest;
ok($#l == -1);

# Then, including our directory

setmoduledirs('./test');
ok($#Module::Find::ModuleDirs == 0);

@l = findsubmod ModuleFindTest;
ok($#l == 0);
ok($l[0] eq 'ModuleFindTest::SubMod');

@l = findallmod ModuleFindTest;
ok($#l == 1);
ok($l[0] eq 'ModuleFindTest::SubMod');
ok($l[1] eq 'ModuleFindTest::SubMod::SubSubMod');

# Third, reset back to @INC only

setmoduledirs();
ok($#Module::Find::ModuleDirs == -1);

@l = findsubmod ModuleFindTest;
ok($#l == -1);

@l = findallmod ModuleFindTest;
ok($#l == -1);

# Fourth, including our directory again

setmoduledirs('./test');
ok($#Module::Find::ModuleDirs == 0);

@l = findsubmod ModuleFindTest;
ok($#l == 0);
ok($l[0] eq 'ModuleFindTest::SubMod');

@l = findallmod ModuleFindTest;
ok($#l == 1);
ok($l[0] eq 'ModuleFindTest::SubMod');
ok($l[1] eq 'ModuleFindTest::SubMod::SubSubMod');


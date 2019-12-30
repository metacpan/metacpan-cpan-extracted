#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use Module::Find;

use lib qw(./t/test);

findsubmod ModuleFindTest;

usesub ModuleFindTest;
ok($ModuleFindTest::SubMod::loaded);
ok(!$ModuleFindTest::SubMod::SubSubMod::loaded);

useall ModuleFindTest;
ok($ModuleFindTest::SubMod::loaded);
ok($ModuleFindTest::SubMod::SubSubMod::loaded);

setmoduledirs('./test');
findallmod ModuleFindTest;


# 00_compile.t - Just make sure Module::AutoLoad compiles

use Test::More tests => 1;
BEGIN { use_ok('Module::AutoLoad') };

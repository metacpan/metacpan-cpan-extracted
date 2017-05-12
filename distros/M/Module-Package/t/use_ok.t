use Test::More tests => 3;

# use_ok calls import and that sets off fireworks!
require Module::Package;
pass 'Module::Package is ok';

use_ok 'Module::Package::Plugin';

# INIT block causes warnings here
local $^W;
use_ok 'Module::Install::Package';

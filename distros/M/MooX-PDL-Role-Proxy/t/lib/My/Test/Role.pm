package My::Test::Role;

use Test::Lib;
use My::Test;

use constant {
    Single => 'My::Test::Role::Single::' . My::Test::NAME,
    Nested => 'My::Test::Role::Nested::' . My::Test::NAME,
};

use Module::Load;

load Single();
load Nested();

1;

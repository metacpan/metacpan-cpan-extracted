package My::Class;

use Test::Lib;
use My::Test;

use constant {
    Single => 'My::Class::Single::' . My::Test::NAME,
    Nested => 'My::Class::Nested::' . My::Test::NAME,
};

use Module::Load;

load Single();
load Nested();

1;

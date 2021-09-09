package My::Test::Role::Single::Piddle;

use Role::Tiny;

with 'My::Test::Role::Single';

use namespace::clean;

sub test_class { 'My::Class::Single::Piddle' }

1;

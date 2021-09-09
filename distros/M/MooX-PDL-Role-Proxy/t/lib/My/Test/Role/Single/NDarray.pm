package My::Test::Role::Single::NDarray;

use Role::Tiny;

with 'My::Test::Role::Single';

use namespace::clean;

sub test_class { 'My::Class::Single::NDarray' }

1;

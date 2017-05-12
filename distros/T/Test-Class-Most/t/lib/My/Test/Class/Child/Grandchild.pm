package My::Test::Class::Child::Grandchild;

use Test::Class::Most parent => 'My::Test::Class::Child';

sub parent { ['My::Test::Class::Child'] }

sub test_functions : Tests(2) {
    ok 1, 'We should still have test functions available';
    eval '$foo = 1';
    ok $@, '... and strict enabled';
}

1;

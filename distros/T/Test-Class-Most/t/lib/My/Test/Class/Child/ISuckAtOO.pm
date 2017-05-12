package My::Test::Class::Child::ISuckAtOO;

use Test::Class::Most parent => [qw/
    My::Test::Class::Child
    My::Test::Class::Child2
/];

sub parent { [qw/My::Test::Class::Child My::Test::Class::Child2/] }

sub multiple_inheritance_sucks : Tests {
    my $test = shift;
    can_ok $test, 'child1';
    is $test->child1, 'from child1', '... and it should return the correct value';
    can_ok $test, 'child2';
    is $test->child2, 'from child2', '... and it should return the correct value';
}

1;

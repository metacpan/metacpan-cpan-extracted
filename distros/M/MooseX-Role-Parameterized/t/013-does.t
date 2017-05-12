use strict;
use warnings;
use Test::More 0.88;
use Test::Moose;

{
    package MyPRole;
    use MooseX::Role::Parameterized;
    role {};
}

{
    package MyClass;
    use Moose;
    with 'MyPRole',
}

my $generated_role = MyClass->meta->roles->[0]->name;
does_ok( 'MyClass', $generated_role, 'class does the generate role' );
does_ok( 'MyClass', 'MyPRole', 'class does the parameterized role' );
cmp_ok(
    $generated_role->meta->get_roles->[0]->name,
    'eq',
    'MyPRole',
    'generated role does the parameterized role'
);

done_testing;

use strict;
use warnings;
use Test::More 0.88;

do {
    package MyRole;
    use MooseX::Role::Parameterized (
        role => { -as => 'parameterized_role' },
        'method',
    );

    parameterized_role {
        method ok => sub {};
    };
};

my $role = MyRole->meta->generate_role;
ok($role->has_method('ok'), "renaming the role block export works");

done_testing;

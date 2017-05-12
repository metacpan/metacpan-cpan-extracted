use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

do {
    package MyRole::Excluder;
    use MooseX::Role::Parameterized;

    parameter exclude => (
        is  => 'rw',
        isa => 'Str',
    );

    role {
        my $p = shift;
        excludes $p->exclude;
    };
};

Moose::Meta::Role->create("Role::A");
Moose::Meta::Role->create("Role::B");

my @keep_roles_alive;
sub excludes_roles {
    map {
        my $role = MyRole::Excluder->meta->generate_role(
            parameters => {
                exclude => $_,
            },
        );
        push @keep_roles_alive, $role;
        $role->name;
    } @_
}

is (exception {
    Moose::Meta::Class->create_anon_class(
        roles => [ excludes_roles('Role::A') ],
    );
}, undef);

{
    my ($role_name) = excludes_roles('Role::A');
    like( exception {
        Moose::Meta::Class->create_anon_class(
            roles => [ 'Role::A', $role_name ],
        );
    }, qr/^Conflict detected: Role $role_name excludes role 'Role::A'/);
}

is (exception {
    Moose::Meta::Class->create_anon_class(
        roles => [ 'Role::B', excludes_roles('Role::A') ],
    );
}, undef);

done_testing;

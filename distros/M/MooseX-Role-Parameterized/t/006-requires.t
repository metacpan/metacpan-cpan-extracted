use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

do {
    package MyRole::Requires;
    use MooseX::Role::Parameterized;

    parameter requires => (
        is  => 'rw',
        isa => 'Str',
    );

    role {
        my $p = shift;
        requires $p->requires;
    };
};

my @keep_roles_alive;
sub requires_names {
    map {
        my $role = MyRole::Requires->meta->generate_role(
            parameters => {
                requires => $_,
            },
        );
        push @keep_roles_alive, $role;
        $role->name;
    } @_
}

{
    my ($role_name) = requires_names('alpha');
    like( exception {
        Moose::Meta::Class->create_anon_class(
            roles => [ $role_name ],
        );
    }, qr/'$role_name' requires the method 'alpha' to be implemented by '[\w:]+'/);
}

is (exception {
    Moose::Meta::Class->create_anon_class(
        methods => {
            alpha => sub {},
        },
        roles => [ requires_names('alpha') ],
    );
}, undef);

{
    my ($role1, $role2) = requires_names('alpha', 'beta');
    like( exception {
        Moose::Meta::Class->create_anon_class(
            methods => {
                alpha => sub {},
            },
            roles => [ $role1, $role2 ],
        );
    }, qr/'$role1\|$role2' requires the method 'beta' to be implemented by '[\w:]+'/);
}

{
    my ($role1, $role2) = requires_names('alpha', 'beta');
    like( exception {
        Moose::Meta::Class->create_anon_class(
            methods => {
                beta => sub {},
            },
            roles => [ $role1, $role2 ],
        );
    }, qr/'$role1\|$role2' requires the method 'alpha' to be implemented by '[\w:]+'/);
}

is (exception {
    Moose::Meta::Class->create_anon_class(
        methods => {
            alpha => sub {},
            beta => sub {},
        },
        roles => [ requires_names('alpha', 'beta') ],
    );
}, undef);

done_testing;

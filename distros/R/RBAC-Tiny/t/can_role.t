use strict;
use warnings;
use Test::More tests => 6;
use RBAC::Tiny;

my $rbac = RBAC::Tiny->new(
    roles => {
        author => {
            can => [ qw<read write publish> ],
        },

        limited_author => {
            all_from => ['author'],
            except   => ['publish'],
        },

        admin => {
            all_from => ['author'],
            can      => ['create_users'],
        },
    },
);

ok(
    $rbac->can_role( author => 'publish' ),
    'author can publish',
);

ok(
    !$rbac->can_role( author => 'create_users' ),
    'author cannot create users',
);

ok(
    $rbac->can_role( admin => 'write' ),
    'admin can write',
);

ok(
    !$rbac->can_role( limited_author => 'publish' ),
    'limited author cannot publish',
);

ok(
    !$rbac->can_role( limited_author => 'create_users' ),
    'limited author cannot create users',
);

ok(
    !$rbac->can_role( author => 'create_users' ),
    'author cannot create users',
);

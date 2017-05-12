use strict;
use warnings;
use Test::More tests => 2;
use RBAC::Tiny;

my $r = RBAC::Tiny->new(
    roles => {
        author => {
            can => [ 'read', 'write' ],
        },

        ro_author => {
            all_from => ['author'],
            can      => ['gossip'],
            except   => ['write'],
        },
    }
);

can_ok( $r, 'roles' );

is_deeply(
    $r->roles,
    {
        author => {
            can => ['read', 'write'],
        },

        ro_author => {
            can => ['read', 'gossip'],
        },
    },
    'Correct structure for author and ro_author',
);

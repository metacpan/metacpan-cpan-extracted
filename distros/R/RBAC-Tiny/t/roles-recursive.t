use strict;
use warnings;
use Test::More tests => 1;
use RBAC::Tiny;

my $r = RBAC::Tiny->new(
    roles => {
        base => {
            can => ['read'],
        },

        author => {
            all_from => ['base'],
            can      => ['write'],
        },

        ro_author => {
            all_from => ['author'],
            can      => ['gossip'],
            except   => ['write'],
        },
    }
);

is_deeply(
    $r->roles,
    {
        base => {
            can => ['read'],
        },

        author => {
            can => ['read', 'write'],
        },

        ro_author => {
            can => ['read', 'gossip'],
        },
    },
    'Correct structure, recursively',
);

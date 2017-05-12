use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;
use RBAC::Tiny;

like(
    exception { RBAC::Tiny->new },
    qr/^'roles' attribute required/,
    'Must provide \'roles\' attribute',
);

{
    my $r;
    is(
        exception { $r = RBAC::Tiny->new( roles => {} ) },
        undef,
        'With \'roles\' attribute it is fine',
    );
}

my $r = RBAC::Tiny->new(
    roles => {
        author => {
            can => [ 'read', 'write' ],
        },
    }
);

can_ok( $r, 'role' );
is_deeply(
    $r->role('author'),
    { can => ['read', 'write'] },
    'role works correctly',
);

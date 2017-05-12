use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;
use RBAC::Tiny;

subtest 'Circular foo <-> bar' => sub {
    my $r = RBAC::Tiny->new(
        roles => {
            foo => {
                all_from => ['bar'],
            },

            bar => {
                all_from => ['foo'],
            },
        }
    );

    like(
        exception { $r->roles },
        qr/^
            Circular \s dependency \s detected \s in \s
            (?:
                'foo' \s and \s 'bar'
                |
                'bar' \s and \s 'foo'
            )
        /x,
        'Catch foo-bar-foo circular reference in all_from',
    );
};

subtest 'Circular foo <-> foo' => sub {
    my $r = RBAC::Tiny->new(
        roles => {
            foo => {
                all_from => ['foo'],
            },
        }
    );

    like(
        exception { $r->roles },
        qr/^Circular dependency detected in 'foo' and 'foo'/,
        'Catch foo-foo circular reference in all_from',
    );
};

subtest 'all_from from unknown role' => sub {
    my $r = RBAC::Tiny->new(
        roles => {
            foo => {
                all_from => ['bar'],
            }
        },
    );

    like(
        exception { $r->roles },
        qr/^Role 'bar' does not exist but used by 'foo'/,
        'Cannot build from non-existent role',
    );
};

subtest 'Build with no data' => sub {
    my $r = RBAC::Tiny->new( roles => {} );
    like(
        exception { $r->role('foo') },
        qr/^No data provided for role 'foo'/,
        'Cannot build a role without any data',
    );
};

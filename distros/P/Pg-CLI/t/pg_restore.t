use strict;
use warnings;

use lib 't/lib';

use Pg::CLI::pg_restore;
use Test::More 0.88;
use Test::PgCLI;

{
    my $pg_restore = Pg::CLI::pg_restore->new( executable => 'pg_restore' );

    test_command(
        'pg_restore',
        sub {
            $pg_restore->run(
                database => 'Foo',
                options  => [ '-c', 'SELECT 1 FROM foo' ]
            );
        },
        sub {
            shift;
            my $cmd = shift;

            ok(
                !$ENV{PGPASSWORD},
                'password is not set in environment when command runs'
            );

            is_deeply(
                $cmd,
                [
                    'pg_restore',
                    '-w',
                    '-d', 'Foo',
                    '-c', 'SELECT 1 FROM foo',
                ],
                'command includes options and -w, but no other connection info'
            );
        },
        );
    }

{
    my $pg_restore = Pg::CLI::pg_restore->new(
        executable => 'pg_restore',
        username   => 'foo',
        password   => 'bar',
        host       => 'foo.example.com',
        port       => 5141,
    );

    test_command(
        'pg_restore',
        sub {
            $pg_restore->run(
                database => 'Foo',
                options  => [ '-c', 'SELECT 1 FROM foo' ]
            );
        },
        sub {
            shift;
            my $cmd = shift;

            is(
                $ENV{PGPASSWORD}, 'bar',
                'password is set in environment when command runs'
            );
            is_deeply(
                $cmd,
                [
                    'pg_restore',
                    '-U', 'foo',
                    '-h', 'foo.example.com',
                    '-p', 5141,
                    '-w',
                    '-d', 'Foo',
                    '-c', 'SELECT 1 FROM foo',
                ],
                'command includes connection info'
            );
        },
    );
}

{
    my $pg_restore = Pg::CLI::pg_restore->new(
        executable => 'pg_restore',
        _version   => '8.3.2',
    );

    test_command(
        'pg_restore',
        sub {
            $pg_restore->run(
                database => 'Foo',
                options  => [ '-c', 'SELECT 1 FROM foo' ]
            );
        },
        sub {
            shift;
            my $cmd = shift;

            is_deeply(
                $cmd,
                [
                    'pg_restore',
                    '-d', 'Foo',
                    '-c', 'SELECT 1 FROM foo',
                ],
                'command includes connection info, but no -w for Pg < 8.4'
            );
        },
    );
}

done_testing();

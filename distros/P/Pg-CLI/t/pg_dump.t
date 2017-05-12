use strict;
use warnings;

use lib 't/lib';

use Pg::CLI::pg_dump;
use Test::More 0.88;
use Test::PgCLI;

{
    my $pg_dump = Pg::CLI::pg_dump->new( executable => 'pg_dump' );

    test_command(
        'pg_dump',
        sub {
            $pg_dump->run(
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
                    'pg_dump',
                    '-w',
                    '-c', 'SELECT 1 FROM foo',
                    'Foo'
                ],
                'command includes options and -w, but no other connection info'
            );
        },
    );
}

{
    my $pg_dump = Pg::CLI::pg_dump->new(
        executable => 'pg_dump',
        username   => 'foo',
        password   => 'bar',
        host       => 'foo.example.com',
        port       => 5141,
    );

    test_command(
        'pg_dump',
        sub {
            $pg_dump->run(
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
                    'pg_dump',
                    '-U', 'foo',
                    '-h', 'foo.example.com',
                    '-p', 5141,
                    '-w',
                    '-c', 'SELECT 1 FROM foo',
                    'Foo'
                ],
                'command includes connection info'
            );
        },
    );
}

{
    my $pg_dump = Pg::CLI::pg_dump->new(
        executable => 'pg_dump',
        _version   => '8.3.2',
    );

    test_command(
        'pg_dump',
        sub {
            $pg_dump->run(
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
                    'pg_dump',
                    '-c', 'SELECT 1 FROM foo',
                    'Foo'
                ],
                'command includes connection info, but no -w for Pg < 8.4'
            );
        },
    );
}

done_testing();

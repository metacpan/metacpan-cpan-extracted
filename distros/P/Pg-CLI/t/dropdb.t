use strict;
use warnings;

use lib 't/lib';

use Pg::CLI::dropdb;
use Test::More 0.88;
use Test::PgCLI;

{
    my $dropdb = Pg::CLI::dropdb->new( executable => 'dropdb' );

    test_command(
        'dropdb',
        sub {
            $dropdb->run(
                database => 'Foo',
            );
        },
        sub {
            shift;
            my $cmd = shift;

            ok(
                !$ENV{PGPASSWORD},
                'password is not set in environment when command runs'
            );
            ok(
                !$ENV{PGSSLMODE},
                'ssl mode is not set in environment when command runs'
            );
            is_deeply(
                $cmd,
                [
                    'dropdb',
                    '-w',
                    'Foo'
                ],
                'command has no options except -w and database name'
            );
        },
    );

    test_command(
        'dropdb',
        sub {
            $dropdb->run(
                database => 'Foo',
                options  => [qw( -e )],
            );
        },
        sub {
            shift;
            my $cmd = shift;

            is_deeply(
                $cmd,
                [
                    'dropdb',
                    '-w',
                    '-e',
                    'Foo'
                ],
                'command includes options passed to run'
            );
        },
    );

    test_command(
        'dropdb',
        sub {
            $dropdb->run(
                database => 'Foo',
                stdin    => \'in',
                stdout   => \'out',
                stderr   => \'err',
            );
        },
        sub {
            shift;
            my $cmd    = shift;
            my $stdin  = shift;
            my $stdout = shift;
            my $stderr = shift;

            is_deeply(
                $cmd,
                [
                    'dropdb',
                    '-w',
                    'Foo',
                ],
                'command has no options except -w and database name'
            );

            is_deeply(
                $stdin,
                \'in',
                'got expected stdin ref'
            );

        },
    );
}

{
    my $dropdb = Pg::CLI::dropdb->new(
        executable  => 'dropdb',
        username    => 'foo',
        password    => 'bar',
        host        => 'foo.example.com',
        port        => 5141,
        require_ssl => 1,
    );

    test_command(
        'dropdb',
        sub {
            $dropdb->run(
                database => 'Foo',
            );
        },
        sub {
            shift;
            my $cmd = shift;

            is(
                $ENV{PGPASSWORD}, 'bar',
                'password is set in environment when command runs'
            );
            is(
                $ENV{PGSSLMODE}, 'require',
                'ssl mode is set in environment when command runs'
            );
            is_deeply(
                $cmd,
                [
                    'dropdb',
                    '-U', 'foo',
                    '-h', 'foo.example.com',
                    '-p', 5141,
                    '-w',
                    'Foo'
                ],
                'command includes connection info'
            );
        },
    );
}

done_testing();

use strict;
use warnings;

use lib 't/lib';

use Pg::CLI::createdb;
use Test::More 0.88;
use Test::PgCLI;

{
    my $createdb = Pg::CLI::createdb->new( executable => 'createdb' );

    test_command(
        'createdb',
        sub {
            $createdb->run(
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
                    'createdb',
                    '-w',
                    'Foo'
                ],
                'command has no options except -w and database name'
            );
        },
    );

    test_command(
        'createdb',
        sub {
            $createdb->run(
                database => 'Foo',
                options  => [qw( -E UTF-8 -O alice )],
            );
        },
        sub {
            shift;
            my $cmd = shift;

            is_deeply(
                $cmd,
                [
                    'createdb',
                    '-w',
                    '-E', 'UTF-8',
                    '-O', 'alice',
                    'Foo'
                ],
                'command includes options passed to run'
            );
        },
    );

    test_command(
        'createdb',
        sub {
            $createdb->run(
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
                    'createdb',
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
    my $createdb = Pg::CLI::createdb->new(
        executable  => 'createdb',
        username    => 'foo',
        password    => 'bar',
        host        => 'foo.example.com',
        port        => 5141,
        require_ssl => 1,
    );

    test_command(
        'createdb',
        sub {
            $createdb->run(
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
                    'createdb',
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

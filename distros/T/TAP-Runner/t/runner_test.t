use warnings;
use strict;
use Test::More;
use Test::Fatal;
use Test::Deep;

plan tests => 4;

    use_ok( 'TAP::Runner::Test' );

    like(
        exception { TAP::Runner::Test->new },
        qr/^Attribute \(file\) is required/,
        'Check that file required',
    );

    cmp_deeply(
        TAP::Runner::Test->new(
            file => 't/test_file.t',
        ),
        all(
            isa( 'TAP::Runner::Test' ),
            methods(
                file  => 't/test_file.t',
                alias => 't/test_file.t',
                harness_tests => [
                    {
                        file  => 't/test_file.t',
                        alias => 't/test_file.t',
                        args  => [],
                    }
                ],
            ),
        ),
        'Check default alias',
    );

    cmp_deeply(
        TAP::Runner::Test->new(
            file    => 't/tests.t',
            alias   => 'Test alias',
            args    => [ '--test' ],
            options => [
                {
                    name => '--opt1',
                    values => [ 1, 2 ],
                },
                {
                    name => '--opt2',
                    values => [ 1, 2 ],
                    multiple => 1,
                },
            ],
        )->harness_tests,
        [
            {
                'file'  => 't/tests.t',
                'alias' => 'Test alias --opt2 1',
                'args'  => [
                    '--test',
                    '--opt1' => 1,
                    '--opt1' => 2,
                    '--opt2' => 1,
                ],
            },
            {
                'file'  => 't/tests.t',
                'alias' => 'Test alias --opt2 2',
                'args'  => [
                    '--test',
                    '--opt1' => 1,
                    '--opt1' => 2,
                    '--opt2' => 2,
                ],
            }
        ],
        'Harness tests variables ( multiple option )',
    );

done_testing;

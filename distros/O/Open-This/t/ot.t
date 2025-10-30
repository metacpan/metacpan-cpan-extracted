use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
use Test::Script qw( script_fails script_runs script_stdout_is );

subtest 'print' => sub {
    my @args = (
        [ '--print', '--editor' ],
        [ '-p',      '-e' ],
        [ '-p',      '--editor' ],
        [ '--print', '-e' ],
    );

    for my $args (@args) {
        script_runs(
            [ './script/ot', @$args, 'kate', 'Open::This line 222' ] );
        my $test_name = join ' ', @$args;
        script_stdout_is( "--line 222 lib/Open/This.pm\n", $test_name );
    }
};

subtest 'json' => sub {
    my @args = (
        [ '--json', '--editor' ],
        [ '-j',     '-e' ],
        [ '-j',     '--editor' ],
        [ '--json', '-e' ],
    );

    for my $args (@args) {
        script_runs(
            [ './script/ot', @$args, 'kate', 'Open::This line 222' ] );
        my $test_name = join ' ', @$args;
        script_stdout_is(
            '{"editor":"kate","editor_args":["--line","222","lib/Open/This.pm"],"success":true}'
                . "\n", $test_name );
    }
};

subtest 'json with details' => sub {
    my @args = (
        '--json', '--editor', 'kate', 'this-does-not-exist.txt',
    );

    script_fails( [ './script/ot', @args ], { exit => 1 }, 'get details' );
    script_stdout_is(
        '{"details":"this-does-not-exist.txt","error":"Could not locate file","success":false}'
            . "\n",
        'details in JSON'
    );
};

done_testing;

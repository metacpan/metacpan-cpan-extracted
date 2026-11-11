use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
use Test::Script qw(
    script_fails
    script_runs
    script_stderr_like
    script_stdout_is
    script_stdout_like
);

use Open::This ();
use Path::Tiny qw( path );

my @browse_stub = ( interpreter_options => [ '-It/lib', '-MOtBrowseStub' ] );
my $abs_path    = path('lib/Open/This.pm')->absolute->stringify;

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

subtest 'help' => sub {
    delete local $ENV{EDITOR};

    for my $flag (qw( --help -h )) {
        script_runs( [ './script/ot', $flag ], "$flag runs" );
        script_stdout_like(
            qr/Usage:.*Parameters:.*-v\|--version:/s,
            "$flag prints usage"
        );
    }
};

subtest 'version' => sub {
    delete local $ENV{EDITOR};

    for my $flag (qw( --version -v )) {
        script_runs( [ './script/ot', $flag ], "$flag runs" );
        script_stdout_is(
            'ot ' . Open::This->VERSION . "\n",
            "$flag prints version"
        );
    }
};

subtest 'bad option without target' => sub {
    script_fails( [ './script/ot', '--bogus' ], { exit => 2 }, 'exits 2' );
    script_stderr_like( qr/Unknown option: bogus/, 'warns about option' );
    script_stderr_like( qr/Usage:/,                'prints usage' );
};

subtest 'bad option without target, json' => sub {
    script_fails(
        [ './script/ot', '--json', '--bogus' ], { exit => 2 },
        'exits 2'
    );
    script_stdout_is(
        '{"error":"Invalid options","success":false}' . "\n",
        'error in JSON'
    );
};

subtest 'bad option with target still opens' => sub {
    script_runs(
        [
            './script/ot', '--bogus', '-p', '-e', 'kate',
            'Open::This line 222'
        ],
        'runs'
    );
    script_stdout_is( "--line 222 lib/Open/This.pm\n", 'prints editor args' );
};

subtest 'browse accepts an absolute path' => sub {
    script_runs(
        [ './script/ot', '--browse', $abs_path ], {@browse_stub},
        'runs'
    );
    script_stdout_is(
        "https://github.com/o/r/blob/topic/lib/Open/This.pm\n",
        'opens repository URL'
    );
};

subtest 'browse relative path' => sub {
    script_runs(
        [ './script/ot', '--browse', 'lib/Open/This.pm' ],
        {@browse_stub},
        'runs'
    );
    script_stdout_is(
        "https://github.com/o/r/blob/topic/lib/Open/This.pm\n",
        'opens repository URL'
    );
};

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Script qw( script_runs script_stdout_is );

my @args = (
    [ '--print', '--editor' ],
    [ '-p',      '-e' ],
    [ '-p',      '--editor' ],
    [ '--print', '-e' ],
);

for my $args (@args) {
    script_runs( [ './script/ot', @$args, 'kate', 'Open::This line 222' ] );
    my $test_name = join ' ', @$args;
    script_stdout_is( "--line 222 lib/Open/This.pm\n", $test_name );
}

done_testing;

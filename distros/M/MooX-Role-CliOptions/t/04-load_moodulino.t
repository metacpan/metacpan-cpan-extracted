#!perl

use strict;
use warnings;

use Test::More;
plan tests => 9;

use Test::Deep;
use Test::Exception;

use Capture::Tiny ':all';

use FindBin;
use lib "$FindBin::Bin/../examples";

my ( $stdout, $stderr, $exit ) = capture {
    require_ok('moodulino.pl');
};
like( $stdout, qr/command line flag not set/, 'cli flag not set' );
like( $stdout, qr/exit was not called/, 'exit was not called by require' );

my $app;
lives_ok { $app = My::Moodulino->init( argv => [] ); } '$app initialized';
isa_ok( $app, 'My::Moodulino', '$app' );
ok( !$app->cli, 'cli attribute was not set by require' );
cmp_deeply(
    $app,
    methods( debug => 1, verbose => 1, argv => [] ),
    'correct defaults were set'
);

lives_ok {
    ( $stdout, $stderr, $exit ) = capture {
        $app->run;
    };
}
'$app->run succeeds';

is( $exit >> 8, 0, 'no error in exit code' );

exit;

__END__

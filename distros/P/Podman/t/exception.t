## no critic
use Test::More;

use English qw( -no_match_vars );

use Podman::Exception;

my %exceptions = (
    900 => 'Connection failed.',
    304 => 'Action already processing.',
    400 => 'Bad parameter in request.',
    404 => 'No such item.',
    409 => 'Conflict error in operation.',
    500 => 'Internal server error.',
    666 => 'Unknown error.',
);

while ( my ( $code, $message ) = each %exceptions ) {
    eval { Podman::Exception->throw($code); };

    is( $EVAL_ERROR->message, $message, 'Exception message ok.' );
    is( $EVAL_ERROR->code,    $code,    'Exception code ok.' );
}

done_testing();

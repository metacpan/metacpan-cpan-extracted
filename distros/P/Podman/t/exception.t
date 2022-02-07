## no critic
use Test::More;

use Try::Tiny;

use Podman::Exception;

my %Messages = (
    0   => 'Connection failed.',
    304 => 'Action already processing.',
    400 => 'Bad parameter in request.',
    404 => 'No such item.',
    409 => 'Conflict error in operation.',
    500 => 'Internal server error.',
    666 => 'Unknown error.',
);

while ( my ( $Code, $Message ) = each %Messages ) {
    try {
        Podman::Exception->new( Code => $Code )->throw();
    }
    catch {
        my $Exception = shift;

        is( $Exception->Message, $Message, 'Exception message ok.' );
        is( $Exception->Code,    $Code,    'Exception code ok.' );

        my $String = sprintf "%s (%d)", $Message, $Code;
        is( $Exception->AsString, $String, 'Exception string ok.' );
    };
}

done_testing();

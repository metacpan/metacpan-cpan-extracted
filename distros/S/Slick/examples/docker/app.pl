use 5.036;

use Slick;

my $slick = Slick->new;
$slick->get(
    '/' => sub {
        my ( $app, $context ) = @_;
        return $context->json( { hello => 'world' } );
    }
);

$slick->run;

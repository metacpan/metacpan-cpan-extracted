
use Mojo::Base '-strict';
use Test::Mojo;
use Test::More;

my $VALUE = 'Foobar';

my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->mode( 'development' );
$t->app->routes->get( '/' => sub {
    my ( $c ) = @_;
    $c->render(
        inline => '<%= auto_reload %>' . $VALUE,
    );
} );
$t->app->plugin( 'AutoReload' );

$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_like( qr{location\.reload}, 'development mode contains script with reload' )
    ;

$t->app->mode( 'production' );
$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_unlike( qr{location\.reload}, 'non-development mode lacks reload' )
    ;

done_testing;

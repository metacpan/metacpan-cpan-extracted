
use Mojo::Base '-strict';
use Test::Mojo;
use Test::More;

# Value contains an HTML entity that turns into a high-byte UTF-8
# character to test that we do not obliterate HTML entities.
my $VALUE = 'Foobar &larr;';

my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->mode( 'development' );
add_routes( $t );
$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_like( qr{location\.reload}, 'development mode contains script with reload using helper' )
    ;
$t->get_ok( '/automatic' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_like( qr{location\.reload}, 'development mode automatically adds script to body tag' )
    ;
$t->get_ok( '/automatic/no-body' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_like( qr{location\.reload}, 'development mode automatically adds script at end without <body> tag' )
    ;

$t = Test::Mojo->new( 'Mojolicious' );
$t->app->mode( 'production' );
add_routes( $t );
$t->get_ok( '/' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_unlike( qr{location\.reload}, 'non-development mode lacks reload with helper' )
    ;
$t->get_ok( '/automatic' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_unlike( qr{location\.reload}, 'non-development mode lacks reload with automatic hook' )
    ;
$t->get_ok( '/automatic/no-body' )
    ->status_is( 200 )
    ->content_like( qr{$VALUE} )
    ->content_unlike( qr{location\.reload}, 'non-development mode lacks reload with automatic hook' )
    ;


done_testing;

sub add_routes {
    my ( $t ) = @_;
    $t->app->routes->get( '/' => sub {
        my ( $c ) = @_;
        $c->render(
            inline => '<%= auto_reload %>' . $VALUE,
        );
    } );
    $t->app->routes->get( '/automatic' => sub {
        my ( $c ) = @_;
        $c->render(
            inline => "<html><body>$VALUE</body></html>",
        );
    } );
    $t->app->routes->get( '/automatic/no-body' => sub {
        my ( $c ) = @_;
        $c->render(
            inline => $VALUE,
        );
    } );
    $t->app->plugin( 'AutoReload' );
}


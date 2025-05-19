use Test2::V0;
use Test2::MojoX;
use Mojolicious::Lite;

my $t = Test2::MojoX->new;

$t->app->log->level('fatal');
ok( lives { $t->app->plugin( CSRF => {
    include => ['/test'],
    exclude => ['/exclude'],
} ) }, 'plugin registration' ) or note $@;

any( '/test' => sub {
    my $c = shift;
    $c->render( text => join( "\n",
        '<title>Test Page</title>',
        '<a href="' . $c->csrf->url_for('/test') . '">Link</a>',
        '<form method="post"></form>',
    ) );
} );

$t->get_ok('/test')->header_like( 'X-CSRF-Token' => qr/^[0-9a-f]{32}$/ );
my $token = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
like( $token, qr/^[0-9a-f]{32}$/, 'CSRF form token' );
like( $t->tx->res->dom->at('a')->attr('href'), qr|^/test\?csrf_token=[0-9a-f]{32}$|, 'url_for' );

$t->post_ok('/test');
like( $t->tx->res->dom->at('title')->text, qr/\bServer Error\b/, 'Server Error Page' );

$t->post_ok( '/test', form => { csrf_token => $token } )->content_like( qr/<title>Test\sPage\b/ );

ok( lives { $t->app->csrf->delete_token }, 'delete_token' ) or note $@;

done_testing;

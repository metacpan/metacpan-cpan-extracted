use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'GoogleFontProxy';

no warnings 'once';

local $Mojolicious::Plugin::GoogleFontProxy::USER_AGENT_STRING = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0';
local $Mojolicious::Plugin::GoogleFontProxy::CSS_URL_FORMAT    = '/file?type=css&version=%s&file=%s';
local $Mojolicious::Plugin::GoogleFontProxy::FONT_URL_FORMAT   = '/file?type=font&file=%s';

get '/' => sub {
    my $c = shift;
    $c->render( 'index' );
};

get '/file' => sub {
    my $c = shift;

    my $params    = $c->tx->req->params->to_hash;
    $params->{ua} = $c->tx->req->headers->user_agent;
    $c->render( json => $params );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_like( qr{/google/css/0/Lato:300,400,700,900} );

my ($url) = '/google/css/0/Lato:300,400,700,900';
$t->get_ok( $url )->status_is(200);

$t->json_is( '/file', 'Lato:300,400,700,900' );
$t->json_is( '/type', 'css' );
$t->json_is( '/ua',   'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0' );

done_testing();

__DATA__
@@ index.html.ep

<link href='https://fonts.googleapis.com/css?family=Lato:300,400,700,900' rel='stylesheet' type='text/css'>

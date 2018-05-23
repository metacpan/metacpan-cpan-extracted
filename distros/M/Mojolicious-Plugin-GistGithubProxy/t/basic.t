use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'GistGithubProxy';

{
no warnings;
$Mojolicious::Plugin::GistGithubProxy::GIST_URL_FORMAT = '/file?user=%s&id=%s&file=%s';
}

get '/' => sub {
    my $c = shift;
    $c->render( 'index' );
};

get '/file' => sub {
    my $c = shift;
    $c->render( json => $c->tx->req->params->to_hash );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_like( qr{/github/gist} );

my ($url) = $t->tx->res->body =~ m{(/github/gist/.*?)"};
$t->get_ok( $url )->status_is(200);

$t->json_is( '/file', 'Kernel_Config_Files_OwnerHook.xml' );
$t->json_is( '/user', 'reneeb' );
$t->json_is( '/id',   'd4abdd63c134d12dde93b23e633d3d3e' );

done_testing();

__DATA__
@@ index.html.ep

<script src="https://gist.github.com/reneeb/d4abdd63c134d12dde93b23e633d3d3e.js?file=Kernel_Config_Files_OwnerHook.xml"></script>

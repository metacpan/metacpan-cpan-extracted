use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'GistGithubProxy' => { user => 'reneeb' };

{
no warnings;
$Mojolicious::Plugin::GistGithubProxy::GIST_URL_FORMAT = '/file?user=%s&id=%s&file=%s';
}

get '/file' => sub {
    my $c = shift;
    $c->render( json => $c->tx->req->params->to_hash );
};

my $t = Test::Mojo->new;
$t->get_ok( '/github/gist/d4abdd63c134d12dde93b23e633d3d3e/Kernel_Config_Files_OwnerHook.xml' )->status_is(200);

$t->json_is( '/file', 'Kernel_Config_Files_OwnerHook.xml' );
$t->json_is( '/user', 'reneeb' );
$t->json_is( '/id',   'd4abdd63c134d12dde93b23e633d3d3e' );

done_testing();


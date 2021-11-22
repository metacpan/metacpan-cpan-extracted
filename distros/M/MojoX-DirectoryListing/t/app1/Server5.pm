package t::app1::Server5;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

# an app that serves / and serves /hidden as an alias
# to t/app1/private

get '/test' => sub { $_[0]->render( text => "Server5" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );
serve_directory_listing( '/' );
serve_directory_listing( '/hidden', 't/app1/private' );

1;

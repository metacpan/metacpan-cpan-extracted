package t::app1::Server6;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

get '/test' => sub { $_[0]->render( text => "Server6" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );
serve_directory_listing( '/', recursive => 1, "show-icon" => 1 );
serve_directory_listing( '/hidden', 't/app1/private', recursive => 1 );

1;

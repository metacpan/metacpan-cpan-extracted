package t::app1::Server2;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

get '/test' => sub { $_[0]->render( text => "Server2" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );
serve_directory_listing( '/', "show-icon" => 1 );
serve_directory_listing( '/dir2/dir3' );

1;

package t::app1::Server3;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

# an app that server /dir2, /dir4,
# and t/app1/public/dir2/dir3 under the alias /dir23.
# It does *not* serve t/app1/public 

get '/test' => sub { $_[0]->render( text => "Server3" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );
serve_directory_listing( '/dir2' );
serve_directory_listing( '/dir4' );
serve_directory_listing( '/dir23', 't/app1/public/dir2/dir3' );

1;

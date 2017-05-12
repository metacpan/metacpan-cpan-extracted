package t::app1::Server4;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

get '/test' => sub { $_[0]->render( text => "Server4" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );
serve_directory_listing( '/', "show-file-time" => 0, "sort-column" => 'N' );
serve_directory_listing( '/dir1', "show-file-type" => 0, "sort-column" => 'S' );
serve_directory_listing( '/dir2', "show-file-size" => 0,
			 "sort-column" => "T", "sort-order" => "D",
			 "show-forbidden" => 1 );

# sort by file size, even though we don't display file size
serve_directory_listing( '/dir2/dir3', "show-file-time" => 0,
			 "show-file-size" => 0, "show-file-type" => 0,
			 "sort-column" => 'S' );
1;

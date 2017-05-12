package t::app1::Server7;
use Mojolicious::Lite;
use MojoX::DirectoryListing;

get '/test' => sub { $_[0]->render( text => "Server7" ) };
MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );

sub serve_dir {
    my $self = shift;
    serve_directory_listing( @_ );
    return $self;
}

1;

package t::app1::Server1;
use Mojolicious::Lite;

# an app that does not serve any directories

get '/test' => sub { $_[0]->render( text => "Server1" ) };
1;

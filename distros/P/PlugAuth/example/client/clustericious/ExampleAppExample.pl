package ExampleAppExample;

use base qw( Clustericious::App );

package ExampleAppExample::Routes;

use Clustericious::RouteBuilder;

get '/' => sub { shift->render(text => 'hello') };

authenticate;
authorize;

get '/some/user/resource' => sub { shift->render(text => 'hello') };

package main;

ExampleAppExample->new->start;

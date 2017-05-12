use Mojo::Base -strict;
use Test::More tests => 6;

use Mojolicious::Lite;
use Test::Mojo;

plugin "Sugar";

get '/flash';
get '/set-flash' => sub {
  my $self = shift;
  $self->flash_add_to('messages' => 'test1');
  $self->flash_add_to('messages' => 'test2');
  $self->flash_add_to('messages' => 'test3', 'test4');
  $self->redirect_to('/flash');
};

get '/test-params' => sub {
  my $self = shift;
  $self->render( text => $self->params->to_hash->{test} );
};

my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

$t->get_ok('/test-params?test=passed')->status_is(200)->content_is('passed');
$t->get_ok('/set-flash')->status_is(200)->content_like(qr/test1,test2,test3,test4/);


__DATA__

@@ flash.html.ep
<%= join(',', @{ flash 'messages' }) =%>

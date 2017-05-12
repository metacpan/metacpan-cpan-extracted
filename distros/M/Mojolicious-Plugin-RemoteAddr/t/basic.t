use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'RemoteAddr';

get '/ip' => sub {
  my $self = shift;
  $self->render( text => $self->remote_addr );
};

# IP from transaction
my $t = Test::Mojo->new;
$t->get_ok('/ip')->status_is(200)->content_is('127.0.0.1', 'IP from transaction');


# IP from X-Real-IP header
$t->ua->on( start => sub {
    my ( $ua, $tx ) = @_;
    $tx->req->headers->header( 'X-Real-IP', '1.1.1.1' );
});
 
$t->get_ok('/ip')->status_is(200)->content_is('1.1.1.1', 'IP from X-Real-IP header');

done_testing();

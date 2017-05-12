#! perl
use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

plugin Sessions3S => {};

app->sessions()->cookie_name( 'saussage' );

ok( app->sessions()->state() );
ok( app->sessions()->sidgen() );
ok( ! app->sessions()->storage() );

get '/hello' => sub {
    my ($self) = @_;
    $self->session( said_hello => 'yup' );
    $self->render( text => 'saying hello' );
};

get '/haveISaidHello' => sub{
    my ($self) = @_;
    $self->render( text => $self->session('said_hello') ? 'yes' : 'nope' );
};

my $t = Test::Mojo->new();

$t->get_ok('/haveISaidHello')->content_like( qr/nope/ );
ok( ! $t->tx->res->every_cookie('saussage')->[0] , "Ok no cookie yet");

$t->get_ok('/hello');

is( $t->tx->res->every_cookie('saussage')->[0]->name() , 'saussage' , "Cookie is set with the right name" );

$t->get_ok('/haveISaidHello')->content_like( qr/yes/ );

done_testing();

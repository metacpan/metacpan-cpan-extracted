#!perl

use Test::More tests => 5;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Mojolicious::Lite;
use Test::Mojo;

use_ok('Mojolicious::Plugin::GroupedParams');

my $t = Test::Mojo->new;

plugin 'grouped_params';

get '/test' => sub {
    my ( $self ) = @_;

    my $p = $self->grouped_params('test');
    $self->render_text("$p->{key1}, $p->{key2}");    

};

$t->get_ok('/test?test.key1=value1&test.key2=value2')
    ->content_is('value1, value2');

get '/test2' => sub {
    my ( $self ) = @_;

    my $p = $self->grouped_params('test');
    $self->render_text("$p->{'splited.key'}");    

};

$t->get_ok('/test2?test.splited.key=value')
    ->content_is('value');

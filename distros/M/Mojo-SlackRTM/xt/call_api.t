
use v5.10;
use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::JSON qw( to_json );
use Mojo::SlackRTM;
local $Mojo::SlackRTM::SLACK_URL = '';

my $mock_ua = Mojo::UserAgent->new;
$mock_ua->server->app( Mojolicious->new );
$mock_ua->server->app->routes->post( '/chat.postMessage' )->to( cb => sub {
    my ( $c ) = @_;
    $c->render( json => $c->req->body_params->to_hash );
} );;

my $slack = Mojo::SlackRTM->new(
    ua => $mock_ua,
    token => 'FAKE',
);

my $json;
$slack->call_api(
    'chat.postMessage',
    { attachments => [ { foo => 'bar' } ] },
    sub {
        my ( $slack, $tx ) = @_;
        $json = $tx->res->json;
        Mojo::IOLoop->stop;
    },
);

Mojo::IOLoop->start;

ok $json, 'got json response for call_api';
is $json->{token}, 'FAKE', 'call_api token is correct';
is $json->{attachments}, to_json([{ foo => 'bar' }]), 'call_api param is json-encoded';

done_testing;

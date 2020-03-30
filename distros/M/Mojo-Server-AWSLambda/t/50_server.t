use Mojo::Base -strict;

use Test::More;
use Mojo::JSON 'decode_json';
use Mojo::Server::AWSLambda;
use Mojolicious::Lite;
use Data::Dumper;

app->log->level('fatal');

get '/' => sub {
    my $c      = shift;
    my $params = $c->req->params->to_hash;
    $c->render( json => { message => $params } );
};

open my $req_fh, '<', 't/payload.json';
my $req_json = do { local $/; <$req_fh> };
close $req_fh;
my $req_data = decode_json($req_json);

my $server   = Mojo::Server::AWSLambda->new( app => app );
my $req      = $server->run();
my $response = $req->($req_data);

is_deeply(
    $response,
    {
        'headers' => {
            'content-type' => 'application/json;charset=UTF-8'
        },
        'isBase64Encoded'   => \0,
        'body'              => '{"message":{"query":"1234ABCD"}}',
        'statusCode'        => 200,
        'multiValueHeaders' => {
            'content-type' => [ 'application/json;charset=UTF-8' ]
        }
    }
);
done_testing;

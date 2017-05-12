use strict;
use warnings;

use LWP::UserAgent;
use Plack::Runner;
use Test::TCP;

my $service_app = sub {
    my $response = '{"response":"ok"}';

    return [
        200,
        ['Content-Type' => 'application/json'],
        [ $response ],
    ];
};

my $service = Test::TCP->new(code => sub {
    my ( $port ) = @_;

    close STDERR;

    my $runner = Plack::Runner->new;
    $runner->parse_options('--listen' => '127.0.0.1:' . $port);
    $runner->run($service_app);
});

sub {
    my ( $env ) = @_;

    if($env->{'PATH_INFO'} eq '/') {
        my $ua  = LWP::UserAgent->new;
        my $req = HTTP::Request->new(GET => 'http://localhost:' . $service->port . '/rpc');
        my $res = $ua->request($req);

        if($res->header('Content-Type') eq 'application/json') {
            return [
                200,
                ['Content-Type' => 'application/json'],
                [ $res->content ],
            ];
        } else {
            return [
                500,
                ['Content-Type' => 'text/plain'],
                [ q{Couldn't reach RPC server} ],
            ];
        }
    } else {
        return [
            404,
            ['Content-Type' => 'text/plain'],
            ['Not Found'],
        ];
    }
};

use strict;
use warnings;
use Plack::Builder;
use Plack::Request;
use Plack::Response;
use lib qw(lib ../lib);

my $default_server = $ENV{REDIS_SERVER} || 'localhost:6379'; # subject to change

=pod

=head1 SYNOPSYS

    % plackup app-basic.psgi

=head1 THROTTLE-FREE REQUESTS

    % curl -v http://localhost:5000/foo/bar

No B<X-Throttle-Lite-*> headers will be displayed. Only content like

    Throttle-free request

=head1 THROTTLED REQUESTS

    % curl -v http://localhost:5000/api/user
    % curl -v http://localhost:5000/api/host

Headers B<X-Throttle-Lite-*> will be displayed with actual values of requests

    X-Throttle-Lite-Limit: 5
    X-Throttle-Lite-Units: req/hour
    X-Throttle-Lite-Used: 3

Content like

    API: User
    API: Host

After limit requests will be equal used requests, additional header appears

    Retry-After: 1239
    X-Throttle-Lite-Expire: 1239
    X-Throttle-Lite-Limit: 5
    X-Throttle-Lite-Units: req/hour
    X-Throttle-Lite-Used: 5

and response code will be

    HTTP/1.0 429 Too Many Requests

with content

    Rate Limit Exceeded

=cut

builder {
    enable 'Throttle::Lite',
        limits => '5 req/hour', backend => [ 'Redis' => {instance => $default_server} ], routes => qr{^/api}i;
    sub {
        my ($env) = @_;
        my $body;

        if (Plack::Request->new($env)->path_info =~ qr{^/api/(user|host)}i) {
            $body = 'API: ' . ucfirst($1);
        }
        else {
            $body = 'Throttle-free request';
        }

        Plack::Response->new(200, ['Content-Type' => 'text/plain'], $body)->finalize;
    };
};

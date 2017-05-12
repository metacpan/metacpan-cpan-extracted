use strict;
use warnings;
use Plack::Builder;
use Plack::Request;
use Plack::Response;
use lib qw(lib ../lib);

=pod

=head1 SYNOPSYS

    % plackup app-whitelist.psgi

=head1 THROTTLE-FREE REQUESTS

    % curl -v http://localhost:5000/foo/bar

No X-Throttle-Lite-* headers will be displayed. Only content like

    Throttle-free request

=head1 THROTTLED REQUESTS

    % curl -v http://localhost:5000/api/user
    % curl -v http://localhost:5000/api/host

Headers will be displayed, limits of 5 req/hour switched to unlimited because of any remote address whitelisted.

    X-Throttle-Lite-Limit: unlimited
    X-Throttle-Lite-Units: req/hour
    X-Throttle-Lite-Used: 14

and content like

    API: User
    API: Host

=cut

builder {
    enable 'Throttle::Lite',
        limits => '5 req/hour', backend => 'Simple', routes => qr{^/api}i,
        whitelist => [ '0.0.0.0/0' ];
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

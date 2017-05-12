package MockUserAgent;
use strict;
use warnings;

use Carp;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;
use Try::Tiny;
use Test::MockObject::Extends;
use LWP::UserAgent;

sub new {
    my ( $class, $app, $ua ) = @_;

    # from Plack::Test::MockHTTP
    if ( !defined $ua ) {
        $ua = LWP::UserAgent->new;
        $ua->env_proxy;
    }
    $ua = Test::MockObject::Extends->new($ua);

    $ua->mock(
        'simple_request',
        sub {
            my ($self,$req) = @_;
            $req->uri->scheme('http')    unless defined $req->uri->scheme;
            $req->uri->host('localhost') unless defined $req->uri->host;
            my $env = $req->to_psgi;

            my $res = try {
                HTTP::Response->from_psgi( $app->($env) );
            }
            catch {
                HTTP::Response->from_psgi(
                    [ 500, [ 'Content-Type' => 'text/plain' ], [$_] ] );
            };

            $res->request($req);
            return $res;
        }
    );
    return $ua;
}

1;

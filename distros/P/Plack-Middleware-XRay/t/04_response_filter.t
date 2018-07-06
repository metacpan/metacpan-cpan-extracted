use 5.12.0;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use Plack::Middleware::XRay;
use HTTP::Request::Common;
use AWS::XRay qw/ capture /;

BEGIN {
    AWS::XRay->auto_flush(0); # effect to t::Util
};
use t::Util qw/ reset segments /;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my $sleep  = $req->parameters->{sleep} || 0;
    my $status = $req->parameters->{status} || 200;

    sleep $sleep;
    [$status, ['Content-Type' => 'text/plain'], ["Hello World\n"]];
};

$app = Plack::Builder::builder {
    enable "XRay",
        name            => "myTest",
        sampling_rate   => 1,
        response_filter => sub {
            my ($env, $res, $elapsed) = @_;
            # when server error or slow response.
            return $res->[0] >= 500 || $elapsed >= 1.5;
        },
    ;
    $app;
};

# not be captured
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
};

# captured by status >= 500
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?status=503");
};

# captured by elasped >= 1
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?sleep=2");
};

# not be captured
test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?sleep=1");
};

my @seg = segments;
is scalar @seg => 2;
is $seg[0]->{http}->{request}->{url} => "http://localhost/?status=503";
is $seg[1]->{http}->{request}->{url} => "http://localhost/?sleep=2";
note explain(@seg);

done_testing;


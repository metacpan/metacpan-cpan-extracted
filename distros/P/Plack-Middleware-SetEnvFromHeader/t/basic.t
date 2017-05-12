use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $test = sub {
    my %options = (@_);
    my $app = builder {
        enable "SetEnvFromHeader" => %options;
        sub {
            my $env = shift;
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ join "\n", map { "$_=$env->{$_}" } keys %$env ]
            ]
        };
    };
};

# Nothing
test_psgi app => $test->(), client => sub {
    my $res = shift->(GET "/");
    is $res->content_type, 'text/plain';
    unlike $res->content, qr/app=/;
};

# REMOTE_USER
test_psgi app => $test->(REMOTE_USER => "X-Proxy-REMOTE-USER"), client => sub {
    my $res = shift->(GET "/", "X-Proxy-REMOTE-USER" => "trs");
    is $res->content_type, 'text/plain';
    like $res->content, qr/^REMOTE_USER=trs$/m;
    like $res->content, qr/^HTTP_X_PROXY_REMOTE_USER=trs$/m;
    unlike $res->content, qr/app=/;
};

# Multiple
test_psgi app => $test->(COLOR => "X-Color", "HTTP_HOST" => "Fake-Host"), client => sub {
    my $res = shift->(GET "/", "X-Color" => "purple", "Fake-Host" => "the.moon");
    is $res->content_type, 'text/plain';
    like $res->content, qr/^COLOR=purple$/m;
    like $res->content, qr/^HTTP_X_COLOR=purple$/m;
    like $res->content, qr/^HTTP_HOST=the\.moon$/m;
    like $res->content, qr/^HTTP_FAKE_HOST=the\.moon$/m;
    unlike $res->content, qr/app=/;
};

done_testing;

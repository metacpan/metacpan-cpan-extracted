use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

plan tests => 9;

my $test = sub {
    my %options = (@_);
    my $app = builder {
        enable "ForceEnv" => %options;
        sub {
            my $env = shift;
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ join '|', join '=', map { $_ => $env->{$_} } keys %$env ]
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
test_psgi app => $test->(REMOTE_USER => "trs"), client => sub {
    my $res = shift->(GET "/");
    is $res->content_type, 'text/plain';
    like $res->content, qr/REMOTE_USER=trs/;
    unlike $res->content, qr/app=/;
};

# Multiple
test_psgi app => $test->(REMOTE_ADDR => "10.0.0.1", foo => "bar"), client => sub {
    my $res = shift->(GET "/");
    is $res->content_type, 'text/plain';
    like $res->content, qr/REMOTE_ADDR=10\.0\.0\.1/;
    like $res->content, qr/foo=bar/;
    unlike $res->content, qr/app=/;
};

done_testing;

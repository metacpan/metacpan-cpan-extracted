use strict;
use Test::More;
use Test::Requires qw(IO::Handle::Util);
use IO::Handle::Util qw(:io_from);
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Plack::Middleware::Deflater;
$Plack::Test::Impl = "Server";

my $app = builder {
    enable sub {
        my $cb = shift;
        sub {
            my $env = shift;
            $env->{"plack.skip-deflater"} = 1;    
            $cb->($env);
        }
    };
    enable 'Deflater', content_type => 'text/plain', vary_user_agent => 1;
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        is $res->content, 'Hello World';
        ok !$res->content_encoding;
        ok !$res->header('Vary');
    };


done_testing;


use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $app = builder {
    enable sub {
        my $cb = shift;
        sub {
            my $env = shift;
            $env->{HTTP_ACCEPT_ENCODING}   =~ s/(gzip|deflate)//gi
                if $env->{HTTP_USER_AGENT} =~ m!^Mozilla/4!
                    and $env->{HTTP_USER_AGENT} !~ m!\bMSIE\s(7|8)!;
            $cb->($env);
            }
    };
    enable 'Deflater', content_type => 'text/plain', vary_user_agent => 1;

    # Non streaming
    # sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }

    # delayed
    sub {
        my $env = shift;
        return sub {
            my $r = shift;
            $r->([ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"]]);
        };
    };
};

my @impl = qw(MockHTTP Server);
sub flip_backend { $Plack::Test::Impl = shift @impl }

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/" );
    $req->accept_decodable;
    $req->user_agent(
        "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Trident/5.0)");
    my $res = $cb->($req);
    is $res->decoded_content,  'Hello World';
    is $res->content_encoding, 'gzip';
    like $res->header('Vary'), qr/Accept-Encoding/;
    like $res->header('Vary'), qr/User-Agent/;
    }
    while flip_backend;

done_testing;

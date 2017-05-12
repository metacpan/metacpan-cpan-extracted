use strict;
use warnings;
use FindBin;
use Test::More tests => 4;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Test::Requires {
    'AnyEvent' => 5.34,
    'Plack::Test::AnyEvent' => 0.03
};

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

    # streaming
    sub {
        my $env = shift;
        return sub {
            my $r = shift;
            my $w = $r->([ '200', [ 'Content-Type' => 'text/plain' ]]);
            my $timer;
            my $i = 0;
            my @message = qw/Hello World/;
            $timer = AnyEvent->timer(
                after => 1,
                interval => 1,
                cb => sub {
                    $w->write($message[$i]. "x" x 1024 . "\n");
                    $i++;
                    if ( $i == 2 ) {
                        $w->close;
                        undef $timer;
                    }
                }
            );
        };
    };
};

local $Plack::Test::Impl = 'AnyEvent';

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        
        my $req = HTTP::Request->new( GET => "http://localhost/" );
        $req->accept_decodable;
        $req->user_agent(
            "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Trident/5.0)");
        my $res = $cb->($req);
        $res->recv;
        like $res->header('Vary'), qr/Accept-Encoding/;
        like $res->header('Vary'), qr/User-Agent/;
        is $res->content_encoding, 'gzip';
        is $res->decoded_content,  "Hello" . "x" x 1024 . "\nWorld" . "x" x 1024 . "\n";
    };


done_testing;

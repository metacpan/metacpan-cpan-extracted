use strict;
use Test::More;
use Test::Requires qw(Furl Test::TCP);
use Plack::Builder;
use Plack::Loader;

my $app = builder {
    enable 'Deflater', content_type => 'text/plain';
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] }
};

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;
        for my $encoding (qw/gzip deflate/) {
            my $furl = Furl->new(
                headers => ['Accept-Encoding',$encoding]
            );
            my $res = $furl->get("http://127.0.0.1:$port/");
            is $res->content, 'Hello World';
            is $res->content_encoding, $encoding;
        }
    },
    server => sub {
        my $port = shift;
        Plack::Loader->load('HTTP::Server::PSGI',host=>'127.0.0.1',port => $port)->run($app);
        exit;
    },
);

done_testing;


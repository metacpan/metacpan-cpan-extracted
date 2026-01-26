use strict;
use warnings;

use Test::More tests => 1;
use Plack::Handler::H2;

my $port = 49156;

# Skip if `curl` isn't available or doesn't support HTTP/2
my $curl_check = `curl --version 2>&1`;
if ($? != 0 || $curl_check !~ /HTTP2/) {
    plan skip_all => 'curl with HTTP/2 support is required for this test';
}

my $pid = fork();
if ($pid) {
    sleep 5;

    my $response = qx[curl --http2 -ski -o /dev/null -w "%{http_code}" https://localhost:$port/];
    is($response, '200', 'Received 200 OK from H2 server');

    kill 'TERM', $pid;
    waitpid($pid, 0);
} else {
    # Child process: start the Plack::Handler::H2 server
    my $app = sub {
        my $env = shift;
        return [200, ['Content-Type' => 'text/plain'], ['Hello, HTTP/2!']];
    };

    my $server = Plack::Handler::H2->new(
        port => $port,
        $ENV{'SSL_CERT_FILE'} ? ( ssl_cert_file => $ENV{'SSL_CERT_FILE'} ) : (),
        $ENV{'SSL_KEY_FILE'} ? ( ssl_key_file  => $ENV{'SSL_KEY_FILE'} ) : ()
    );

    $server->run($app);
}

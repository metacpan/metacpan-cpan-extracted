use 5.016;

use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new;
$ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;
        say $tx->req->method, ' ', $tx->req->url;
        $tx->on(
            finish => sub {
                my $tx = shift;
                say $tx->req->method, ' ', $tx->req->url;
            }
        );
    }
);
my $proxy_url = 'http://bbexternalproxy.stagecourier.com:8888';
local $ENV{HTTPS_PROXY} = $proxy_url;
local $ENV{HTTP_PROXY} = $proxy_url;
local $ENV{MOJO_PROXY} = 1;
use Data::Dumper;
print Dumper $ua->post('http://posttestserver.com/post.php', { foo => 'bar' } );

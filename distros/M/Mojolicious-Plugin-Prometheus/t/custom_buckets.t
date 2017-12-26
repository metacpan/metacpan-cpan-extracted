use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Prometheus' =>
    { request_buckets => [qw/1 2 3/], response_buckets => [qw/4 5 6/], };

get '/' => sub {
    my $c = shift;
    $c->render( text => 'Hello Mojo!' );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_like(qr/Hello Mojo!/);

$t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))
    ->content_like(qr/http_request_size_bytes_count\{method="GET"\} 2/);

done_testing();

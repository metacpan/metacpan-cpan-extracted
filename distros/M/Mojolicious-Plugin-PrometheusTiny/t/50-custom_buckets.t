use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite -signatures;
use Test::Mojo;

plugin 'PrometheusTiny' => (
    request_buckets  => [ 1, 2, 3 ],
    response_buckets => [ 4, 5, 6 ],
    duration_buckets => [ 5, 55, 555 ],
);

get '/' => sub($c) {
    $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;

$t->get_ok('/')
    ->status_is(200)
    ->content_type_like(qr(^text/html));

$t->get_ok('/metrics')
    ->status_is(200)
    ->content_type_like(qr(^text/plain))
    ->content_like(qr/http_request_duration_seconds_bucket\{le="55",/)
    ->content_like(qr/http_request_size_bytes_bucket\{le="3",/)
    ->content_like(qr/http_response_size_bytes_bucket\{code="200",le="6",/);

done_testing();
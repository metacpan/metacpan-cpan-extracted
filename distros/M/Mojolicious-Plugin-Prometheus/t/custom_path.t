use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin Prometheus => { path => '/vidar' };

my $t = Test::Mojo->new;

$t->get_ok('/vidar')->status_is(200)->content_type_like(qr(^text/plain))->content_like(qr/http_request_duration_seconds/);

done_testing();

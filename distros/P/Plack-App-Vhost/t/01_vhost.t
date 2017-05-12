use strict;
use Test::More;

use Plack::App::Vhost;

my $app = Plack::App::Vhost->new(
    vhosts => [
        qr/^foo-mode\.my-app/ => sub { 'foo' },
        qr/^bar-mode\.my-app/ => sub { 'bar' },
    ],
    fallback => sub { 'fallback' },
)->to_app();

is $app->({ HTTP_HOST => 'foo-mode.my-app.foobar.net' }), 'foo',      'valid vhost routing for foo.';
is $app->({ HTTP_HOST => 'bar-mode.my-app.foobar.net' }), 'bar',      'valid vhost routing for bar.';
is $app->({ HTTP_HOST => 'baz-mode.my-app.foobar.net' }), 'fallback', 'valid vhost routing for baz. (fallback)';
is_deeply+Plack::App::Vhost->new->to_app->({ HTTP_HOST => 'foo-mode.my-app.foobar.net' }), [
    404,
    ['Content-Type' => 'text/plain', 'Content-Length' => 9],
    ['not found']
], 'default fallback is 404.';

done_testing;

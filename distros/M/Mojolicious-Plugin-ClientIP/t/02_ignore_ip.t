use strict;
use warnings;

use Test::More;
use Test::Mojo;

{
    use Mojolicious::Lite;

    plugin 'ClientIP', ignore => [qw(192.0.2.2 192.0.2.16/28)];

    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;
}

my $web = Test::Mojo->new;
my $xff = 'X-Forwarded-For';

$web->get_ok('/')
    ->content_is('127.0.0.1');

$web->get_ok('/', { $xff => '192.0.2.1' })
    ->content_is('192.0.2.1');

$web->get_ok('/', { $xff => '192.0.2.2' })
    ->content_is('127.0.0.1');

$web->get_ok('/', { $xff => '192.0.2.1, 192.0.2.2, 10.0.0.1' })
    ->content_is('192.0.2.1');

$web->get_ok('/', { $xff => '192.0.2.17, 192.0.2.2, 10.0.0.1' })
    ->content_is('127.0.0.1');

done_testing;

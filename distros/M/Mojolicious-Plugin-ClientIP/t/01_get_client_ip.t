use strict;
use warnings;

use Test::More;
use Test::Mojo;

{
    use Mojolicious::Lite;

    plugin 'ClientIP';

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

subtest 'ignore private IPs in XFF as default' => sub {
    $web->get_ok('/', { $xff => '127.0.0.2' })
        ->content_is('127.0.0.1');

    $web->get_ok('/', { $xff => '10.0.0.1' })
        ->content_is('127.0.0.1');

    $web->get_ok('/', { $xff => '172.16.0.1' })
        ->content_is('127.0.0.1');

    $web->get_ok('/', { $xff => '192.168.0.1' })
        ->content_is('127.0.0.1');
};

subtest 'multiple IPs in XFF' => sub {
    $web->get_ok('/', { $xff => '10.0.0.1, 192.0.2.1' })
        ->content_is('192.0.2.1');

    $web->get_ok('/', { $xff => '192.0.2.1, 10.0.0.1' })
        ->content_is('192.0.2.1');

    $web->get_ok('/', { $xff => '10.0.0.1, 192.0.2.1, 10.0.0.2' })
        ->content_is('192.0.2.1');

    $web->get_ok('/', { $xff => '10.0.0.1, 192.0.2.1, 192.0.2.2, 10.0.0.2' })
        ->content_is('192.0.2.2');
};

done_testing;

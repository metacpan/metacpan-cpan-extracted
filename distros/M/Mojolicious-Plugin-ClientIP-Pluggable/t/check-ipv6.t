use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Warnings;

# allow 127.0.0.1 be fetched in tests
$ENV{CLIENTIP_PLUGGABLE_SKIP_LOOPBACK} = 0;
{

    use Mojolicious::Lite;

    plugin 'ClientIP::Pluggable',
        analyze_headers => [qw/cf-connecting-ip true-client-ip/],
        restrict_family => 'ipv6',
        fallbacks       => [qw/rfc-7239 x-forwarded-for remote_address/];

    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;
}

my $t = Test::Mojo->new;

subtest "cf-connecting-ip" => sub {
    my $tx = $t->ua->build_tx(
        GET => '/' => {
            'cf-connecting-ip' => '1.2.3.4',
            'true-client-ip'   => '2400:cb00:f00d:dead:beef:1111:2222:3333'
        });
    $t->request_ok($tx)->content_is('2400:cb00:f00d:dead:beef:1111:2222:3333');
};

subtest "ignore rfc-7239 ipv4" => sub {
    my $tx = $t->ua->build_tx(
        GET => '/' => {
            'forwarded'       => 'for=2.2.2.2',
            'x-forwarded-for' => '2400:cb00:f00d:dead:beef:1111:2222:3333'
        });
    $t->request_ok($tx)->content_is('2400:cb00:f00d:dead:beef:1111:2222:3333');
};

subtest "rfc-7239, complex" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'forwarded' => 'for=192.168.0.1;proto=http;by=198.51.100.17, For="[2400:cb00:f00d::17]:4711"'});
    $t->request_ok($tx)->content_is('2400:cb00:f00d::17');
};

done_testing;

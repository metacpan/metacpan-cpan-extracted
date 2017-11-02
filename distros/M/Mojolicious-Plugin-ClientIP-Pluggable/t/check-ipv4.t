use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Warnings;

# allow 127.0.0.1 be fetched in tests
$ENV{CLIENTIP_PLUGGABLE_ALLOW_LOOPBACK} = 1;
{

    use Mojolicious::Lite;

    plugin 'ClientIP::Pluggable',
        analyze_headers => [qw/cf-pseudo-ipv4 cf-connecting-ip true-client-ip/],
        restrict_family => 'ipv4',
        fallbacks       => [qw/rfc-7239 x-forwarded-for remote_address/];

    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;
}

my $t = Test::Mojo->new;

subtest "cf-pseudo-ipv4" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'cf-pseudo-ipv4' => '1.2.3.4'});
    $t->request_ok($tx)->content_is('1.2.3.4');
};

subtest "x-forwarded-for" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'x-forwarded-for' => '1.1.1.1,2.2.2.2'});
    $t->request_ok($tx)->content_is('1.1.1.1');
};

subtest "x-forwarded-for, no private net match" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'x-forwarded-for' => '192.168.0.1,2.2.2.2'});
    $t->request_ok($tx)->content_is('2.2.2.2');
};

subtest "remote_address fallback" => sub {
    my $tx = $t->ua->build_tx(GET => '/');
    $t->request_ok($tx)->content_is('127.0.0.1');
};

subtest "non-ip in header" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'cf-pseudo-ipv4' => 'a1.2.3.4'});
    $t->request_ok($tx)->content_is('127.0.0.1');
};

subtest "ipv6 ignored" => sub {
    my $tx = $t->ua->build_tx(
        GET => '/' => {
            'cf-connecting-ip' => '2400:cb00:f00d:dead:beef:1111:2222:3333',
            'x-forwarded-for'  => '1.1.1.1'
        });
    $t->request_ok($tx)->content_is('1.1.1.1');
};

subtest "rfc-7239, simple and valid" => sub {
    my $tx = $t->ua->build_tx(
        GET => '/' => {
            'forwarded'       => 'for=2.2.2.2',
            'x-forwarded-for' => '1.1.1.1'
        });
    $t->request_ok($tx)->content_is('2.2.2.2');
};

subtest "rfc-7239, complex" => sub {
    my $tx = $t->ua->build_tx(GET => '/' => {'forwarded' => 'for=192.168.0.1;proto=http;by=198.51.100.17, for=108.61.218.131'});
    $t->request_ok($tx)->content_is('108.61.218.131');
};

done_testing;
